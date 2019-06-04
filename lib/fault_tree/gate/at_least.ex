defmodule FaultTree.Gate.AtLeast do
  @moduledoc """
  Handling for ATLEAST logic gates.

  P(A occurs K out of N times) = P(A:K of N) = (N/K) * P(A)^K * (1 - P(A))^(N-K)
  P(A atleast K of N) =  sum(P(A:K of N), ..., P(A:N of N))
  """

  alias FaultTree.Math

  def probability({min, total}, [child | _rest]) do
    calc(child.probability, min, total)
  end

  @doc """
  Calculate exactly K out of N occurances.
  """
  def exact_calc(prob, k, n) do
    t1 = Decimal.div(Decimal.new(n), Decimal.new(k))
    t2 = Math.pow(prob, k)
    t3 = Decimal.sub(1, prob) |> Math.pow(n - k)

    t1 |> Decimal.mult(t2) |> Decimal.mult(t3)
  end

  def calc(prob, k, n) do
    k..n
    |> Stream.map(fn i -> exact_calc(prob, i, n) end)
    |> Enum.reduce(0, &Decimal.add/2)
  end
end
