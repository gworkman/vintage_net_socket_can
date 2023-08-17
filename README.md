# VintageNetSocketCan

This package exposes an interface to automatically configure a SocketCAN inteface through VintageNet. It supports options for setting the CAN bus bitrate and configuration. Under the hood, it uses the `SocketCANd` server to expose a TCP interface to connect to the CAN bus. Options to configure the network interface and port that the server binds to are also configurable.

To use this package in Nerves, it requires several additional kernel packages to enable socketcan. In BusyBox config, add the following options:

```
CONFIG_CAN=y
CONFIG_CAN_MCP251X=y # or another package for your driver
```

And in your Buildroot configuration, add the following:

```
BR2_PACKAGE_LIBSOCKETCAN=y
BR2_PACKAGE_IPROUTE2=y
BR2_PACKAGE_SOCKETCAND=y
```

You may need to adjust your `config.txt` and `fwup.conf` files in a custom nerves system to ensure that you correctly load the driver for your CAN adapter.

I hope to eventually open source and maintain some packages which include CAN support out of the box.

## Usage

In your VintageNet config, add the following:

```elixir
config :vintage_net,
  # regulatory_domain: "00",
  config: [
    {"wlan0",
      %{
          type: VintageNetWiFi
          # ....
        }
    },
    {"can0",
     %{
       type: VintageNetSocketCan,
       bitrate: 125_000,
       port: 29536,
       bind_interface: "wlan0",
       loopback: false
     }}
  ]
```

Or configure it via `VintageNet.configure("can0", %{type: VintageNetSocketCan, bitrate: 125_000, port: 29536, bind_interface: "wlan0", loopback: false})`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `vintage_net_socket_can` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:vintage_net_socket_can, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/vintage_net_socket_can>.
