defmodule M2XNerves.StatusLED do
  require Logger

  use ExActor.GenServer, export: __MODULE__

  defmodule State, do: defstruct [:led_pid]

  @led_pin Application.get_env(:m2x_nerves, :led_gpio)

  defstart start_link do
    Logger.debug("Starting pin #{@led_pin} as output")

    {:ok, pid} = Gpio.start_link(@led_pin, :output)

    initial_state(%State{led_pid: pid})
  end

  defcast stop, state: state do
    Gpio.stop(state.led_pid)

    stop_server(:normal)
  end

  defcast on, state: state do
    Logger.debug("LED on")
    Gpio.write(state.led_pid, 1)

    noreply()
  end

  defcast off, state: state do
    Logger.debug("LED off")
    Gpio.write(state.led_pid, 0)

    noreply()
  end
end
