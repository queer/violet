# violet

violet is a simple etcd client written in Elixir, only used for my personal
projects.

## Installation

Add this to your mix.exs:

```elixir
def deps do
  [
    {:violet, github: "queer/violet"}
  ]
end
```

## Configuration

Put something like this in your config.exs:

```elixir
config :violet, :etcd,
  :url, "http://localhost:2379"
```