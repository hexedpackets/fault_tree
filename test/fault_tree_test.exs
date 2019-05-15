defmodule FaultTreeTest do
  use ExUnit.Case
  doctest FaultTree

  test "simplest or gate" do
    tree = FaultTree.create(:or)
    |> FaultTree.add_basic(0, "0.01", "foo")
    |> FaultTree.add_basic(0, "0.01", "bar")
    |> FaultTree.build()

    assert tree.node.probability == Decimal.new("0.02")
  end
end
