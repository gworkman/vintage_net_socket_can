# VintageNetSocketCAN

This library provides a `VintageNet` technology for the SocketCAN interface. It only supports Linux, and requires hardware which supports SocketCAN.

## Nerves Support
This library was designed with Nerves support in mind, though it supports any Linux platform which enables the SocketCAN kernel module. In the official Nerves systems,
SocketCAN is not enabled by default.

Nerves support of SocketCAN can be achieved by adding the following to `nerves_defconfig`

```
BR2_PACKAGE_LIBSOCKETCAN=y
BR2_PACKAGE_IPROUTE2=y
```

and by enabling `CONFIG_CAN=y` in `linux-6.1.defconfig`. Additional hardware drivers may also be necessary depending on your platform.

## Other resources

Some other resources regarding SocketCAN in Elixir:
- [Elixir SocketCAN library](#)
- [How to support SocketCAN in Nerves with MCP2515 SPI to CAN transciever](#)

## Installation

The package can be installed by adding `vintage_net_socket_can` to your list of dependencies in `mix.exs`:

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

