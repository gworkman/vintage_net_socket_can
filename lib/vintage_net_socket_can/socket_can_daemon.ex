defmodule VintageNetSocketCan.SocketCanDaemon do
  use GenServer
  require Logger

  @typedoc false
  @type init_args :: [
          ifname: VintageNet.ifname(),
          config: map(),
          opts: keyword()
        ]

  @enforce_keys [:ifname, :config]
  defstruct [
    :ifname,
    :config,
    :ifup,
    :bind_ifup,
    :pid,
    opts: [log_output: :debug, stderr_to_stdout: true]
  ]

  @doc """
  Start the SocketCanDaemon
  """
  @spec start_link(init_args()) :: GenServer.on_start()
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  @doc """
  Return whether the daemon is running
  """
  @spec running?(GenServer.server()) :: boolean()
  def running?(server) do
    GenServer.call(server, :running?)
  end

  @impl GenServer
  def init(init_args) do
    state = struct!(__MODULE__, init_args)
    {:ok, state, {:continue, :continue}}
  end

  @impl GenServer
  def handle_continue(:continue, %{ifname: ifname, config: config} = state) do
    VintageNet.subscribe(lower_up_property(ifname))
    VintageNet.subscribe(connection_property(config.bind_interface))

    bind_ifup =
      config.bind_interface
      |> connection_property()
      |> VintageNet.get()
      |> then(fn connection -> connection == :internet end)

    new_state =
      state
      |> Map.put(:ifup, VintageNet.get(lower_up_property(ifname)))
      |> Map.put(:bind_ifup, bind_ifup)
      |> maybe_start_stop_daemon()

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call(:running?, _from, state) do
    {:reply, state.pid != nil and Process.alive?(state.pid), state}
  end

  @impl GenServer
  def handle_info(
        {VintageNet, ["interface", _ifname, "lower_up"], _old_value, true, _meta},
        state
      ) do
    state = %{state | ifup: true}

    {:noreply, maybe_start_stop_daemon(state)}
  end

  @impl GenServer
  def handle_info(
        {VintageNet, ["interface", _ifname, "lower_up"], _old_value, not_true, _meta},
        state
      ) do
    state = %{state | ifup: not_true}

    # Physical layer is down or disconnected. We're definitely disconnected.
    {:noreply, maybe_start_stop_daemon(state)}
  end

  @impl GenServer
  def handle_info(
        {VintageNet, ["interface", _ifname, "connection"], _old_value, connection, _meta},
        state
      ) do
    bind_ifup = connection == :internet

    state = %{state | bind_ifup: bind_ifup}

    {:noreply, maybe_start_stop_daemon(state)}
  end

  # start daemon when both interfaces are up but pid is nil
  defp maybe_start_stop_daemon(%{pid: nil, ifup: true, bind_ifup: true} = state) do
    Logger.debug("Starting SocketCANd")

    {:ok, pid} =
      MuonTrap.Daemon.start_link(
        "socketcand",
        ["-i", state.ifname, "-l", state.config.bind_interface, "-p", "#{state.config.port}"],
        log_output: :info
      )

    %{state | pid: pid}
  end

  defp maybe_start_stop_daemon(%{pid: pid, ifup: true, bind_ifup: true} = state) when is_pid(pid),
    do: state

  defp maybe_start_stop_daemon(%{pid: pid} = state) when is_pid(pid) do
    Logger.debug("stopping socketcand : #{inspect(state)}")

    if Process.alive?(pid), do: GenServer.stop(pid)

    %{state | pid: nil}
  end

  defp maybe_start_stop_daemon(state), do: state

  defp lower_up_property(ifname) do
    ["interface", ifname, "lower_up"]
  end

  defp connection_property(ifname) do
    ["interface", ifname, "connection"]
  end
end
