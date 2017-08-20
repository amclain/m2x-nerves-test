defmodule M2XNerves.InputMonitor do
  require Logger

  alias M2XNerves.StatusLED

  # TODO: Refactor to genserver ################################################

  # @input_pin Applciation.get_env(:m2x_nerves_input, :inputpin)[:pin]
  @input_pin 26

  def start_link do
    Logger.debug("Starting input on pin #{@input_pin}")

    {:ok, input_pid} = Gpio.start_link(@input_pin, :input)
    {:ok, led_pid} = StatusLED.start_link

    spawn fn ->
      Gpio.set_int(input_pid, :both)
      listen_to_pin(led_pid)
    end

    {:ok, input_pid}
  end

  defp listen_to_pin(led_pid) do
    receive do
      {:gpio_interrupt, pin, edge} ->
        Logger.debug("Received #{edge} event on pin #{pin}")

        case edge do
          :rising -> StatusLED.on(led_pid)
          _       -> StatusLED.off(led_pid)
        end
    end

    listen_to_pin(led_pid)
  end
end
