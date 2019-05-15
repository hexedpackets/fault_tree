defmodule FaultTree.Gate.Or do
  @moduledoc """
  Handling for OR logic gates.
  """

  def probability(nodes) do
    nodes
    |> Stream.map(fn n -> n.node.probability end)
    |> Enum.reduce(Decimal.new(0), fn p, acc -> Decimal.add(p, acc) end)
  end
end
