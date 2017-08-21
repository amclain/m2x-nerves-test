defmodule M2XNerves.M2X do
  use ExActor.GenServer, export: __MODULE__

  alias M2XNerves.Network
  alias M2XNerves.StatusLED

  defmodule State, do: defstruct [:command_timer]

  @host "https://api-m2x.att.com"
  @api_key Application.get_env(:m2x_nerves, :api_key)
  @device_id Application.get_env(:m2x_nerves, :device_id)
  @switch_stream_name Application.get_env(:m2x_nerves, :m2x_switch_stream_name)

  defstart start_link do
    command_timer = Process.send_after(self(), :check_commands, 10)

    initial_state(%State{command_timer: command_timer})
  end

  defcast stop do
    stop_server(:normal)
  end

  defcast update_switch_state(switch_state, timestamp \\ DateTime.utc_now) do
    body = Poison.encode!(%{
      timestamp: timestamp |> DateTime.to_iso8601,
      values: %{@switch_stream_name => switch_state},
    })

    if Network.connected? && clock_initialized?() do
      HTTPotion.post("#{@host}/v2/devices/#{@device_id}/update", body: body, headers: headers())
    end

    noreply()
  end

  defhandleinfo :check_commands, state: state do
    state.command_timer |> Process.cancel_timer

    if Network.connected? && clock_initialized?() do
      check_commands()
    end

    command_timer = Process.send_after(self(), :check_commands, 1000)

    new_state(%State{state | command_timer: command_timer})
  end

  defp headers do
    ["X-M2X-KEY": @api_key, "CONTENT-TYPE": "application/json"]
  end

  defp clock_initialized? do
    now = DateTime.utc_now
    {:ok, base, _} = DateTime.from_iso8601("2000-01-01T00:00:00Z")

    DateTime.diff(now, base) > 0
  end

  defp check_commands do
    res =
      HTTPotion.get("#{@host}/v2/devices/#{@device_id}/commands?status=pending", headers: headers())
      .body
      |> Poison.decode!

    res["commands"]
    |> Enum.each(fn(%{"id" => command_id, "name" => name}) ->
      process_command(name, command_id)
      mark_command_processed(command_id)
    end)
  end

  defp process_command("led_state", command_id) do
    led_state =
      get_command_details(command_id)["data"]["state"]
      |> String.to_integer

    if led_state > 0, do: StatusLED.on, else: StatusLED.off
  end

  defp process_command(_, _command_id), do: nil

  defp get_command_details(command_id) do
    HTTPotion.get("#{@host}/v2/devices/#{@device_id}/commands/#{command_id}", headers: headers())
    .body
    |> Poison.decode!
  end

  defp mark_command_processed(command_id) do
    HTTPotion.get(
      "#{@host}/v2/devices/#{@device_id}/commands/#{command_id}/process",
      headers: headers()
    )
  end
end
