defmodule FaultTree do
  @moduledoc """
  Main module for creating and interacting with fault trees.
  """

  use TypedStruct
  require Logger
  alias FaultTree.Node

  typedstruct do
    field :next_id, integer(), default: 0
    field :nodes, list(Node.t()), default: []
  end

  @type error_type :: {:error, String.t()}
  @type result :: t() | error_type()

  @doc """
  Create a new fault tree with an `OR` gate as the root.
  """
  @spec create() :: t()
  def create(), do: create(:or)

  @doc """
  Create a new fault tree with the passed in `Node` as the root.
  """
  @spec create(Node.t()) :: t()
  def create(root = %Node{}) do
    %FaultTree{next_id: root.id + 1, nodes: [root]}
  end

  @doc """
  Create a new fault tree and generate a node of the given type for the root.
  """
  @spec create(atom) :: t()
  def create(root_type) when root_type != :basic do
    %Node{id: 0, name: "root", type: root_type}
    |> create()
  end

  @doc """
  Add a node to the fault tree. Some validations are performed to make sure the node can
  logically be added to the tree.
  """
  @spec add_node(FaultTree.t(), Node.t()) :: result()
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
  Add a basic node to the fault tree with a pre-defined probability.
  """
  def add_basic(tree, probability, name), do: add_basic(tree, nil, probability, name, nil)
  def add_basic(tree, parent, probability, name), do: add_basic(tree, parent, probability, name, nil)

  def add_basic(tree, parent, probability, name, description) do
    node = %Node{type: :basic, name: name, probability: Decimal.new(probability),
                 parent: parent, description: description}
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
  Add a transfer node. This is a reference to a node that already exists in the tree. Transfer nodes cannot have anything modified,
  changes must happen on the source.
  """
  def add_transfer(tree, parent, source) do
    node = %Node{type: :transfer, source: source, name: source, parent: parent}
    add_node(tree, node)
  end

  @doc """
  Perform some validation for a new node against the existing tree.
  """
  def validate_node(tree, node) do
    with {:ok, tree} <- validate_parent(tree, node),
         {:ok, tree} <- validate_probability(tree, node),
         {:ok, tree} <- validate_atleast(tree, node),
         {:ok, tree} <- validate_transfer(tree, node),
         {:ok, tree} <- validate_name(tree, node) do
      {:ok, tree}
    else
      err -> err
    end
  end

  @doc """
  Validate that the name of the node is unique in the fault tree.
  """
  def validate_name(tree, %{type: :transfer, name: name, source: source}) when name == source, do: {:ok, tree}
  def validate_name(tree, %{name: new_name}) do
    case Enum.find(tree.nodes, fn %{name: name} -> name == new_name end) do
      nil -> {:ok, tree}
      _ -> {:error, "Name already exists in the tree"}
    end
  end

  @doc """
  Validate that the gate types allow setting this node as a child of its listed parent.
  """
  def validate_parent(tree, %Node{parent: nil}), do: {:ok, tree}
  def validate_parent(tree, node) do
    parent = find_by_field(tree, :name, node.parent)
    case parent do
      nil -> {:error, "Parent not found in tree"}
      %Node{type: :basic} -> {:error, "Basic nodes cannot have children"}
      %Node{type: :transfer} -> {:error, "Transfer nodes cannot have children"}
      %Node{type: :atleast} ->
        case {node.type, find_children(parent, tree.nodes)} do
          {_, []} -> {:ok, tree}
          {:transfer, children} ->
            case Enum.filter(children, fn %{name: name} -> name != node.name end) do
              [] -> {:ok, tree}
              _ -> {:error, "ATLEAST gates can only have a single child node"}
            end
          {_, _} -> {:error, "ATLEAST gates can only have a single child node"}
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
  Validate that TRANSFER gates have a source that exists in the tree.
  """
  def validate_transfer(tree, node = %Node{type: :transfer}) do
    case find_by_field(tree, :name, node.source) do
      nil -> {:error, "Source not found for TRANSFER gate"}
      _ -> {:ok, tree}
    end
  end
  def validate_transfer(tree, _node), do: {:ok, tree}

  @doc """
  Convert a tree to JSON.
  """
  @spec to_json(t() | map()) :: String.t()
  def to_json(tree = %FaultTree{}), do: tree |> build() |> to_json()
  def to_json(tree) do
    Poison.encode!(tree)
  end

  def build(tree), do: FaultTree.Analyzer.process(tree)

  @doc """
  Convert from a string containing fault tree logic into the tree object.
  """
  @spec parse(String.t()) :: t()
  def parse(doc), do: FaultTree.Parser.XML.parse(doc)

  def find_children(%Node{type: :transfer}, _nodes), do: []
  def find_children(node, nodes), do: Enum.filter(nodes, fn x -> x.parent == node.name end)
  defp find_by_field(tree, field, value), do: tree.nodes |> Enum.find(fn node -> Map.get(node, field) == value end)
end
