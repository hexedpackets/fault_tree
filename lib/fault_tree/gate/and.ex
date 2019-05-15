defmodule FaultTree.Gate.And do
  @moduledoc """
  Handling for AND logic gates.
  """

  def probability(nodes) do
    nodes
    |> Stream.map(fn n -> n.node.probability end)
    |> Enum.reduce(Decimal.new(1), fn p, acc -> Decimal.mult(p, acc) end)
  end
end
