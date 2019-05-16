defmodule FaultTree.Gate.Or do
  @moduledoc """
  Handling for OR logic gates.

  P (A or B) = P (A ∪ B) = P(A) + P(B) - P (A ∩ B)
  """

  def probability(nodes) do
    nodes
    |> Stream.map(fn node -> node.probability end)
    |> Enum.reduce(Decimal.new(0), &calc/2)
  end

  defp calc(a, b) do
    t1 = Decimal.add(a, b)
    t2 = Decimal.mult(a, b)
    Decimal.sub(t1, t2)
  end
end
