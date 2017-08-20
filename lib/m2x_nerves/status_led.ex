defmodule M2XNerves.StatusLED do
  require Logger

  # TODO: Refactor to genserver ################################################

  @output_pin 44

  def start_link do
    Logger.debug("Starting pin #{@output_pin} as output")

    Gpio.start_link(@output_pin, :output)
  end

  def on(pid) do
    Logger.debug("LED on")
    Gpio.write(pid, 1)
  end

  def off(pid) do
    Logger.debug("LED off")
    Gpio.write(pid, 0)
  end
end
