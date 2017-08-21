defmodule M2XNerves.InputMonitor do
  require Logger

  use ExActor.GenServer

  alias M2XNerves.M2X

  defmodule State, do: defstruct [:input_pid]

  @input_pin Application.get_env(:m2x_nerves, :switch_gpio)

  defstart start_link do
    Logger.debug("Starting input on pin #{@input_pin}")

    {:ok, input_pid} = Gpio.start_link(@input_pin, :input)

    Gpio.set_int(input_pid, :both)

    initial_state(%State{input_pid: input_pid})
  end

  defcast stop, state: state do
    Gpio.stop(state.input_pin)

    stop_server(:normal)
  end

  defhandleinfo {:gpio_interrupt, @input_pin, edge}, state: state do
    Logger.debug("Received #{edge} event on pin #{@input_pin}")

    case edge do
      :rising -> M2X.update_switch_state(1)
      _ -> M2X.update_switch_state(0)
    end

    noreply()
  end
end
