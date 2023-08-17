defmodule VintageNetSocketCan do
  require Logger

  alias VintageNet.Interface.RawConfig

  @behaviour VintageNet.Technology

  @required_config [
    bitrate: :integer,
    port: :integer,
    bind_interface: :string,
    loopback: :boolean
  ]

  defguard is_non_empty_string(str) when is_binary(str) and str != ""
  defguard is_non_non_negative_integer(int) when is_integer(int) and int > 0

  @impl VintageNet.Technology
  def normalize(%{type: __MODULE__} = config) do
    _ = ensure_required!(config, @required_config)

    config
  end

  defp ensure_required!(config, schema) do
    for {key, type} <- schema do
      case {config[key], type} do
        {v, :string} when is_non_empty_string(v) -> :ok
        {v, :integer} when is_non_non_negative_integer(v) -> :ok
        {v, :boolean} when is_boolean(v) -> :ok
        _ -> raise ArgumentError, ":#{key} is required"
      end
    end
  end

  @impl VintageNet.Technology
  def to_raw_config(ifname, %{type: __MODULE__} = config, _opts) do
    normalized = normalize(config)

    %RawConfig{
      ifname: ifname,
      type: __MODULE__,
      source_config: normalized,
      child_specs: [
        {MuonTrap.Daemon,
         ["socketcand", ["-i", ifname, "-l", config.bind_interface, "-p", "#{config.port}"]]}
      ],
      required_ifnames: [config.bind_interface],
      up_cmds: [
        maybe_add_interface(ifname),
        {:run, "ip", init_device_args(ifname, config.bitrate, config.loopback)},
        {:run_ignore_errors, "ip", ["addr", "flush", "dev", ifname, "label", ifname]},
        {:run, "ip", ["link", "set", ifname, "up"]}
      ],
      up_cmd_millis: 2_000,
      down_cmds: [
        {:run_ignore_errors, "ip", ["addr", "flush", "dev", ifname, "label", ifname]},
        {:run, "ip", ["link", "set", ifname, "down"]}
      ],
      down_cmd_millis: 2_000,
      retry_millis: 1_000
    }
  end

  defp maybe_add_interface(ifname) do
    case System.cmd("ip", ["link", "show", ifname]) do
      {_, 0} -> []
      _ -> {:run_ignore_errors, "ip", ["link", "add", ifname, "type", "can"]}
    end
  end

  defp init_device_args(ifname, bitrate, false),
    do: ["link", "set", ifname, "type", "can", "bitrate", "#{bitrate}"]

  defp init_device_args(ifname, bitrate, true),
    do: ["link", "set", ifname, "type", "can", "bitrate", "#{bitrate}", "loopback", "on"]

  @impl VintageNet.Technology
  def check_system(_opts), do: {:error, "unimplemented"}

  @impl VintageNet.Technology
  def ioctl(_ifname, _cmd, _args), do: {:error, :unsupported}
end
