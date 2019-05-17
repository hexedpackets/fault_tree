defmodule FaultTree.Analyzer do
  @moduledoc """
  Handles building a fault tree out of an array of nodes.
  """

  alias FaultTree.Analyzer.Probability
  alias FaultTree.Gate
  alias FaultTree.Node
  require Logger

  @doc """
  Converts a `FaultTree` struct into a hierarchical map.
  """
  def process(tree) do
    {:ok, pid} = GenServer.start_link(Probability, nil)

    result = tree
    |> find_root()
    |> process(tree, pid)

    GenServer.stop(pid)
    result
  end

  defp process(node, tree, pid) do
    children = node
    |> FaultTree.find_children(tree.nodes)
    |> Enum.map(fn n -> process(n, tree, pid) end)

    node
    |> Map.put(:children, children)
    |> probability(tree, pid)
    |> Probability.save(pid)
  end

  @doc """
  Calculate the probability of failure for a given node.
  The node must have all of its children with defined probabilities.

  For TRANSFER gates, the probability is copied from the source node. If the
  source node was not calculated before the transfer gate is reached, the probability
  will be calculated twice. This will be inefficient, but mathemetically correct.
  """
  def probability(node = %Node{type: :basic}, _tree, _pid), do: node
  def probability(node = %Node{probability: p}, _tree, _pid) when p != nil, do: node
  def probability(node = %Node{}, tree, pid) do
    p =
      case node.type do
        :or -> Gate.Or.probability(node.children)
        :and -> Gate.And.probability(node.children)
        :atleast -> Gate.AtLeast.probability(node.atleast, node.children)
        :transfer ->
          # Use the source probability for TRANSFER gates.
          src = tree |> find_source_node(node.source)
          case Probability.lookup(src, pid) do
            nil -> src |> process(tree, pid) |> Map.get(:probability)
            res -> res
          end
      end
    Map.put(node, :probability, p)
  end

  defp find_root(tree), do: Enum.find(tree.nodes, &valid_root?/1)

  defp valid_root?(%Node{type: :basic}), do: false
  defp valid_root?(%Node{type: :transfer}), do: false
  defp valid_root?(%Node{parent: :nil}), do: true
  defp valid_root?(_), do: false

  defp find_source_node(tree, source) do
    tree.nodes
    |> Stream.filter(fn %Node{type: type} -> type != :transfer end)
    |> Enum.find(fn %Node{name: name} -> name == source end)
  end
end
