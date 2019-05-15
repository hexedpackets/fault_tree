defmodule FaultTreeTest do
  use ExUnit.Case
  doctest FaultTree

  setup do
    or_tree = FaultTree.create(:or)
    |> FaultTree.add_basic("root", "0.01", "foo")
    |> FaultTree.add_basic("root", "0.01", "bar")

    %{or_tree: or_tree}
  end

  test "simplest or gate", %{or_tree: or_tree} do
    tree = FaultTree.build(or_tree)

    assert tree.node.probability == Decimal.new("0.02")
  end

  test "multi level or gate", %{or_tree: or_tree} do
    tree = or_tree
    |> FaultTree.add_or_gate("root", "l2")
    |> FaultTree.add_basic("l2", "0.02", "l2_foo")
    |> FaultTree.add_basic("l2", "0.02", "l2_bar")
    |> FaultTree.build()

    assert tree.node.probability == Decimal.new("0.06")
  end
end
