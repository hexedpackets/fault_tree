# FaultTree

FaultTree is a library for performing [fault tree analysis](https://en.wikipedia.org/wiki/Fault_tree_analysis). It includes a small HTTP server capable of graphing the resulting FTA, or returning it as JSON.

## Installation

The FaultTree package can be installed from Hex
by adding `fault_tree` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fault_tree, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/fault_tree](https://hexdocs.pm/fault_tree).

## Running

Run the server with `mix trot.server`, or `iex -S mix` for an interactive shell. The analysis can be run by uploading XML at http://localhost:4000/.


## Input format

The expected input is an XML document matching the [SCRAM/openpsa format](https://github.com/rakhimov/scram/blob/master/share/input.rng). Alternatively, the fault tree can be created using Elixir code. Example:


```elixir
FaultTree.create(:or)
|> FaultTree.add_basic("root", "0.01", "foo")
|> FaultTree.add_basic("root", "0.01", "bar")
|> FaultTree.build()
```

Will build the following tree:

```elixir
%FaultTree.Node{
  atleast: nil,
  children: [
    %FaultTree.Node{
      atleast: nil,
      children: [],
      description: nil,
      id: 2,
      name: "bar",
      parent: "root",
      probability: #Decimal<0.01>,
      source: nil,
      type: :basic
    },
    %FaultTree.Node{
      atleast: nil,
      children: [],
      description: nil,
      id: 1,
      name: "foo",
      parent: "root",
      probability: #Decimal<0.01>,
      source: nil,
      type: :basic
    }
  ],
  description: nil,
  id: 0,
  name: "root",
  parent: nil,
  probability: #Decimal<0.0199>,
  source: nil,
  type: :or
}
```
