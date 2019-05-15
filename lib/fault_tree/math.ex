defmodule FaultTree.Math do
  @moduledoc """
  Helper math functions.
  """

  require Integer

  def pow(_, 0), do: 1
  def pow(x, n) when Integer.is_odd(n), do: pow(x, n - 1) |> Decimal.mult(x)
  def pow(x, n) do
    result = pow(x, div(n, 2))
    Decimal.mult(result, result)
  end
end
