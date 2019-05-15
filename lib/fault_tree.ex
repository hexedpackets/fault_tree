defmodule FaultTree do
  @moduledoc """
  Documentation for FaultTree.
  """

  defmodule Node do
    use TypedStruct

    @typedoc """
    Logic gate type for a node.
    """
    @type node_type :: :basic | :or | :and | :atleast

    @typedoc """
    A single node in the fault tree.

    id: unique ID for the node
    parent: ID of the parent node. `0` represents the root node
    type: Gate type for the node
    name: Unique name for the node
    description: Verbose description of the node
    probability: Probability of failure. Calculated for all logic gate types, must be set for `:basic`
    """
    typedstruct enforce: true do
      field :id, integer()
      field :parent, integer(), default: 0
      field :type, node_type(), default: :basic
      field :name, String.t()
      field :description, enforce: false
      field :probability, Decimal.t()
    end
  end
end
