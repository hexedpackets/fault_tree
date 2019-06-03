defmodule FaultTree.Parser.XML do
  @moduledoc """
  Parse an XML document into a FaultTree.
  The XML schema expected is mostly for opsa-mef, defined at:
  [https://github.com/rakhimov/scram/blob/master/share/input.rng](https://github.com/rakhimov/scram/blob/master/share/input.rng)
  """

  import SweetXml
  alias FaultTree.Node

  @doc """
  Parse the XML document into a FaultTree.

  Steps:
  - create a new tree
  - parse xml and add all events/gates to the tree
  - walk the tree and set parent field for anything showing up as a child of another node
    - for duplicates, set all references after the first as a transfer gate
  - walk the tree again and remove original child references

  Things missing:
  - parameter parsing
  - only the first defined fault-tree will be parsed
  - unsupported gate types
  - nested gates are not supported, each gate must be defined with `define-gate` and only use event refs
  - boolean events
  - a bunch of other things from https://raw.githubusercontent.com/rakhimov/scram/master/share/input.rng
  """
  @spec parse(String.t()) :: map()
  def parse(doc) do
    tree = %FaultTree{}
    root = doc |> xpath(~x"/opsa-mef"e)

    mapped = root |> xmap(
      gates: [
        ~x"define-fault-tree/define-gate"l,
        name: ~x"@name | name/text()"s,
        description: ~x"@label | label/text()"os,
        type: ~x"name(or|and|atleast)"s |> transform_by(&String.to_atom/1),
        atleast_min: ~x"atleast/@min"io,
        children: ~x"*/event"l |> transform_by(&transform_events/1),
      ],
      events: [
        ~x"define-fault-tree/define-basic-event | model-data/define-basic-event"l,
        name: ~x"@name"s,
        description: ~x"@label | label/text()"os,
        probability: ~x"float/@value | int/@value"s |> transform_by(&Decimal.new/1),
      ]
    )

    # Add all the basic events to the tree, without parents
    tree = mapped
    |> Map.get(:events)
    |> Stream.map(&convert_event/1)
    |> Enum.reduce(tree, fn node, tree -> FaultTree.add_node(tree, node) end)

    # Add all gates
    tree = mapped
    |> Map.get(:gates)
    |> Stream.map(&convert_gate/1)
    |> Enum.reduce(tree, fn node, tree -> FaultTree.add_node(tree, node) end)

    # Set parent attributes
    tree.nodes
    |> Enum.reduce(tree, fn node, tree ->
      parents = tree.nodes |> Enum.filter(fn %{children: children} -> children != nil and node.name in children end)
      case parents do
        [] -> tree
        [first | rest] -> tree |> set_parent(node, first) |> add_duplicate_children(node, first) |> add_transfers(node, rest)
      end
    end)
    # Null out the child field, which will be a list of strings
    |> Map.update!(:nodes, fn nodes -> nodes |> Enum.map(fn n -> Map.put(n, :children, []) end) end)
  end

  defp convert_event(event), do: Node |> struct(event) |> Map.put(:type, :basic)

  defp convert_gate(gate) do
    case Map.pop(gate, :atleast_min) do
      {nil, gate} -> struct(Node, gate)
      {k, gate} ->
        n = Enum.count(gate.children)
        Node |> struct(gate) |> Map.put(:atleast, {k, n})
    end
  end

  defp set_parent(tree, child, parent) do
    Map.update!(tree, :nodes, fn nodes ->
      Enum.map(nodes, fn node ->
        if node.id == child.id, do: Map.put(node, :parent, parent.name), else: node
      end)
    end)
  end

  defp add_duplicate_children(tree, child, parent) do
    count = parent.children |> Enum.filter(fn c -> c == child.name end) |> Enum.count()
    1..count
    |> Enum.drop(1)
    |> Enum.reduce(tree, fn _, tree -> FaultTree.add_transfer(tree, parent.name, child.name) end)
  end

  defp add_transfers(tree, _node, []), do: tree
  defp add_transfers(tree, node, [parent | rest]) do
    tree
    |> FaultTree.add_transfer(parent.name, node.name)
    |> add_duplicate_children(node, parent)
    |> add_transfers(node, rest)
  end

  defp transform_events(nodes), do: nodes |> Enum.flat_map(&add_duplicate_events/1)

  defp add_duplicate_events(node) do
    event = node
    |> xpath(~x".", name: ~x"./@name"s, count: ~x"./@count"io |> transform_by(&one_if_nil/1))

    1..event[:count]
    |> Enum.map(fn _ -> event[:name] end)
  end

  defp one_if_nil(nil), do: 1
  defp one_if_nil(x), do: x
end
