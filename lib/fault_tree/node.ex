defmodule FaultTree.Node do
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
  atleast: Tuple of {k,n} for ATLEAST gate calculation
  """
  typedstruct do
    field :id, integer()
    field :parent, String.t()
    field :type, node_type(), default: :basic
    field :name, String.t(), enforce: true
    field :description, String.t()
    field :probability, Decimal.t()
    field :atleast, {integer(), integer()}
  end
end
