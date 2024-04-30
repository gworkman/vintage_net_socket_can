defmodule VintageNetSocketCAN do
  @moduledoc """
  Use (SocketCAN)[https://docs.kernel.org/networking/can.html] with VintageNet

  This module is not intended to be called directly but via calls to `VintageNet`. Here's an
  example:

  ```elixir
  VintageNet.configure(
    "can0",
    %{
      type: VintageNetSocketCAN,
      bitrate: 125_000,
      loopback: false
    }
  )
  ```

  The following keys are required:

  * `:bitrate` - the bitrate of the CAN bus. The supported values vary based on the hardware
  * `:loopback` - whether the hardware should operate in loopback mode, ie messages sent on CAN_TX are received on CAN_RX. Useful for testing and development without hardware

  """

  @behaviour VintageNet.Technology

  alias VintageNet.Interface.RawConfig
  require Logger

  @required_config [
    bitrate: :integer,
    loopback: :boolean
  ]

  defguard is_non_empty_string(str) when is_binary(str) and str != ""
  defguard is_non_non_negative_integer(int) when is_integer(int) and int > 0

  @impl VintageNet.Technology
  def normalize(%{type: __MODULE__} = config) do
    ensure_required!(config, @required_config)
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
      child_specs: [{VintageNet.Connectivity.LANChecker, ifname}],
      required_ifnames: [],
      up_cmds: [
        maybe_add_interface(ifname),
        {:run_ignore_errors, "ip", ["addr", "flush", "dev", ifname, "label", ifname]},
        {:run_ignore_errors, "ip", ["link", "set", ifname, "down"]},
        {:run, "ip", init_device_args(ifname, normalized.bitrate, normalized.loopback)},
        {:run, "ip", ["link", "set", ifname, "up"]}
      ],
      up_cmd_millis: 2_000,
      down_cmds: [
        {:run_ignore_errors, "ip", ["addr", "flush", "dev", ifname, "label", ifname]},
        {:run, "ip", ["link", "set", ifname, "down"]}
      ],
      down_cmd_millis: 2_000,
      retry_millis: 5_000
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
