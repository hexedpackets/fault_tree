defmodule FaultTree do
  @moduledoc """
  Documentation for FaultTree.
  """

  use TypedStruct
  require Logger
  alias FaultTree.Node
  alias FaultTree.Gate

  defmodule Node do
    use TypedStruct

    @typedoc """
    Logic gate type for a node.
    """
    @type node_type :: :basic | :or | :and | :atleast

    @typedoc """
    A single node in the fault tree.

    id: unique ID for the node
    parent: ID of the parent node
    type: Gate type for the node
    name: Unique name for the node
    description: Verbose description of the node
    probability: Probability of failure. Calculated for all logic gate types, must be set for `:basic`
    """
    typedstruct do
      field :id, integer()
      field :parent, integer()
      field :type, node_type(), default: :basic
      field :name, String.t(), enforce: true
      field :description, String.t()
      field :probability, Decimal.t()
    end
  end

  typedstruct do
    field :next_id, integer(), default: 0
    field :nodes, list(Node.t()), default: []
  end

  def create(root_type \\ :or) when root_type != :basic do
    root = %Node{id: 0, name: "root", type: root_type}
    %FaultTree{next_id: 1, nodes: [root]}
  end

  def add_node(tree, node) do
    id = tree.next_id
    node = node |> Map.put(:id, id)

    case validate_parent(tree, node) do
      {:error, msg} ->
        Logger.error(msg)
        {:error, :invalid_parent}
      {:ok, tree} ->
        tree
        |> Map.put(:next_id, id + 1)
        |> Map.update!(:nodes, fn nodes -> [node | nodes] end)
    end
  end

  def add_basic(tree, parent, probability, name, description \\ nil) do
    node = %Node{name: name, probability: Decimal.new(probability), parent: parent, description: description}
    add_node(tree, node)
  end

  @doc """
  Validate that the gate types allow setting this node as a child of its listed parent.
  """
  def validate_parent(tree, node) do
    parent = tree.nodes |> Enum.find(fn n -> n.id == node.parent end)
    case parent do
      nil -> {:error, "Parent not found in tree"}
      %Node{type: :basic} -> {:error, "Basic nodes cannot have children"}
      _ -> {:ok, tree}
    end
  end

  @doc """
  Calculate the probability of failure for a given node. The node must have all of its children with defined probabilities.
  """
  def probability(node = %{node: %Node{type: :basic}}), do: node
  def probability(node = %{node: %Node{probability: p}}) when p != nil, do: node
  def probability(%{node: node, children: children}) do
    p =
      case node.type do
        :or -> Gate.Or.probability(children)
      end
    %{node: Map.put(node, :probability, p), children: children}
  end

  @doc """
  Converts a `FaultTree` struct into a hierarchical map.
  """
  def build(tree) do
    tree
    |> find_root()
    |> build(tree)
  end

  defp build(node, tree) do
    children = node
    |> find_children(tree.nodes)
    |> Enum.map(fn n -> build(n, tree) end)

    %{node: node, children: children}
    |> probability()
  end

  defp find_children(node, nodes), do: Enum.filter(nodes, fn x -> x.parent == node.id end)
  defp find_root(tree), do: find_by_id(tree, 0)
  defp find_by_id(tree, id), do: tree.nodes |> Enum.find(fn %{id: i} -> i == id end)
end
