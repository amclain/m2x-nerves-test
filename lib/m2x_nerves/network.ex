defmodule M2XNerves.Network do
  require Logger

  alias Nerves.Network

  @interface "eth0"
  @settings [ipv4_address_method: :dhcp]
  @m2x_hostname "att.m2x.com"

  def start_link do
    GenServer.start_link(__MODULE__, {@interface, @settings}, [name: __MODULE__])
  end

  def connected?, do: GenServer.call(__MODULE__, :connected?)

  def ip_address, do: GenServer.call(__MODULE__, :ip_address)

  def test_connectivity do
    :inet_res.gethostbyname(@m2x_hostname)
  end

  def init({interface, settings}) do
    Network.setup(interface, settings)
    SystemRegistry.register

    {:ok, %{interface: interface, ip_address: nil, connected: false}}
  end

  def handle_info({:system_registry, :global, registry}, state) do
    ip = get_in(registry, [:state, :network_interface, state.interface, :ipv4_address])

    if ip != state.ip_address, do: Logger.info("IP address changed: #{ip}")

    connected = match?(
      {:ok, {:hostent, @m2x_hostname, [], :inet, 4, _}}, test_connectivity()
    ) || false

    {:noreply, %{state | ip_address: ip, connected: connected}}
  end

  def handle_info(_, state), do: {:noreply, state}

  def handle_call(:connected?, _from, state), do: {:reply, state.connected, state}
  def handle_call(:ip_address, _from, state), do: {:reply, state.ip_address, state}
end
