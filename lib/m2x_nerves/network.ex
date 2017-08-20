defmodule M2XNerves.Network do
  require Logger

  use ExActor.GenServer, export: __MODULE__

  alias Nerves.Network

  defmodule State, do: defstruct [:interface, :ip_address, :connected]

  @interface "eth0"
  @settings [ipv4_address_method: :dhcp]
  @connectivity_check_hostname 'google.com'

  defstart start_link do
    Network.setup(@interface, @settings)
    SystemRegistry.register

    initial_state(%State{interface: @interface, ip_address: nil, connected: false})
  end

  defcall connected?, state: state, do: set_and_reply(state, state.connected)
  defcall ip_address, state: state, do: set_and_reply(state, state.ip_address)

  defhandleinfo {:system_registry, :global, registry}, state: state do
    ip = get_in(registry, [:state, :network_interface, state.interface, :ipv4_address])

    if ip != state.ip_address, do: Logger.info("IP address changed: #{ip}")

    connected = match?(
      {:ok, {:hostent, @connectivity_check_hostname, [], :inet, 4, _}},
      test_connectivity()
    )

    new_state(%State{state | ip_address: ip, connected: connected})
  end

  def test_connectivity do
    :inet_res.gethostbyname(@connectivity_check_hostname)
  end
end
