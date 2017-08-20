defmodule M2XNerves.M2X do
  use ExActor.GenServer, export: __MODULE__

  alias M2XNerves.Network

  @host "https://api-m2x.att.com"
  @api_key Application.get_env(:m2x_nerves, :api_key)
  @device_id Application.get_env(:m2x_nerves, :device_id)
  @switch_stream_name Application.get_env(:m2x_nerves, :m2x_switch_stream_name)

  defstart start_link do
    initial_state(%{})
  end

  defcast stop do
    stop_server(:normal)
  end

  defcast update(pin_state, timestamp \\ DateTime.utc_now) do
    body = Poison.encode!(%{
      timestamp: timestamp |> DateTime.to_iso8601,
      values: %{@switch_stream_name => pin_state},
    })

    if Network.connected? && clock_initialized?() do
      HTTPotion.post("#{@host}/v2/devices/#{@device_id}/update", body: body, headers: headers())
    end

    noreply()
  end

  defp headers do
    ["X-M2X-KEY": @api_key, "CONTENT-TYPE": "application/json"]
  end

  defp clock_initialized? do
    now = DateTime.utc_now
    {:ok, base, _} = DateTime.from_iso8601("2000-01-01T00:00:00Z")

    DateTime.diff(now, base) > 0
  end
end
