defmodule FaultTree do
  @moduledoc """
  Documentation for FaultTree.
  """

  use TypedStruct
  require Logger
  alias FaultTree.Node
  alias FaultTree.Gate

  typedstruct do
    field :next_id, integer(), default: 0
    field :nodes, list(Node.t()), default: []
  end

  @doc """
  Create a new fault tree with an `OR` gate as the root.
  """
  def create(), do: create(:or)

  @doc """
  Create a new fault tree with the passed in `Node` as the root.
  """
  def create(root = %Node{}) do
    %FaultTree{next_id: root.id + 1, nodes: [root]}
  end

  @doc """
  Create a new fault tree and generate a node of the given type for the root.
  """
  def create(root_type) when root_type != :basic do
    %Node{id: 0, name: "root", type: root_type}
    |> create()
  end

  @doc """
  Add a node to the fault tree. Some validations are performed to make sure the node can
  logically be added to the tree.
  """
  def add_node(tree, node) do
    id = tree.next_id
    node = node |> Map.put(:id, id)

    case validate_node(tree, node) do
      {:error, msg} ->
        Logger.error(msg)
        {:error, :invalid}
      {:ok, tree} ->
        tree
        |> Map.put(:next_id, id + 1)
        |> Map.update!(:nodes, fn nodes -> [node | nodes] end)
    end
  end

  @doc """
  Add a basic node to the fault tree. Basic events have a pre-defined probability.
  """
  def add_basic(tree, parent, probability, name, description \\ nil) do
    node = %Node{type: :basic, name: name, probability: Decimal.new(probability), parent: parent, description: description}
    add_node(tree, node)
  end

  @doc """
  Add a logic gate to the fault tree.
  """
  def add_logic(tree, parent, type, name, description \\ nil) do
    node = %Node{type: type, name: name, parent: parent, description: description}
    add_node(tree, node)
  end

  @doc """
  Add an OR gate to the fault tree. Any child nodes failing will cause this node to fail.
  """
  def add_or_gate(tree, parent, name, description \\ nil), do: add_logic(tree, parent, :or, name, description)

  @doc """
  Add an AND gate to the fault tree. All children must fail for this node to fail.
  """
  def add_and_gate(tree, parent, name, description \\ nil), do: add_logic(tree, parent, :and, name, description)

  @doc """
  Add an ATLEAST/VOTING gate to the fault tree. This rqeuires that a minimum of K out of N child nodes fail in
  order to be marked as failing.
  """
  def add_atleast_gate(tree, parent, min, total, name, description \\ nil) do
    node = %Node{type: :atleast, name: name, parent: parent, description: description, atleast: {min, total}}
    add_node(tree, node)
  end

  @doc """
  Perform some validation for a new node against the existing tree.
  """
  def validate_node(tree, node) do
    with {:ok, tree} <- validate_parent(tree, node),
         {:ok, tree} <- validate_probability(tree, node),
         {:ok, tree} <- validate_atleast(tree, node) do
      {:ok, tree}
    else
      err -> err
    end
  end

  @doc """
  Validate that the gate types allow setting this node as a child of its listed parent.
  """
  def validate_parent(tree, node) do
    parent = tree.nodes |> Enum.find(fn n -> n.name == node.parent end)
    case parent do
      nil -> {:error, "Parent not found in tree"}
      %Node{type: :basic} -> {:error, "Basic nodes cannot have children"}
      %Node{type: :atleast} ->
        case find_children(parent, tree.nodes) do
          [] -> {:ok, tree}
          _ -> {:error, "ATLEAST gates can only have a single child node"}
        end
      _ -> {:ok, tree}
    end
  end

  @doc """
  Validate that a probability is only set on basic nodes.
  Logic gates will have their probability calculated when the tree is built.
  """
  def validate_probability(tree, node) do
    case node do
      %Node{type: :basic, probability: p} when p > 0 and p != nil -> {:ok, tree}
      %Node{type: :basic} -> {:error, "Basic events must have a probability set"}
      %Node{probability: p} when p > 0 and p != nil -> {:error, "Only basic events should have a probability set"}
      _ -> {:ok, tree}
    end
  end

  @doc """
  Validate that ATLEAST gates have their parameters set.
  """
  def validate_atleast(tree, node) do
    case node do
      %Node{type: :atleast, atleast: nil} -> {:error, "ATLEAST gates must have minimum and total set"}
      _ -> {:ok, tree}
    end
  end

  @doc """
  Calculate the probability of failure for a given node.
  The node must have all of its children with defined probabilities.
  """
  def probability(node = %{node: %Node{type: :basic}}), do: node
  def probability(node = %{node: %Node{probability: p}}) when p != nil, do: node
  def probability(%{node: node, children: children}) do
    p =
      case node.type do
        :or -> Gate.Or.probability(children)
        :and -> Gate.And.probability(children)
        :atleast -> Gate.AtLeast.probability(node.atleast, children)
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

  defp find_children(node, nodes), do: Enum.filter(nodes, fn x -> x.parent == node.name end)
  defp find_root(tree), do: find_by_id(tree, 0)
  defp find_by_id(tree, id), do: tree.nodes |> Enum.find(fn %{id: i} -> i == id end)
end
