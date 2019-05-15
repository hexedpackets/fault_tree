defmodule FaultTreeTest do
  use ExUnit.Case
  doctest FaultTree

  setup do
    or_tree = FaultTree.create(:or)
    |> FaultTree.add_basic("root", "0.01", "foo")
    |> FaultTree.add_basic("root", "0.01", "bar")

    and_tree = FaultTree.create(:and)
    |> FaultTree.add_basic("root", "0.01", "foo")
    |> FaultTree.add_basic("root", "0.01", "bar")

    %{or_tree: or_tree, and_tree: and_tree}
  end

  test "OR gate probability", %{or_tree: tree} do
    tree = FaultTree.build(tree)
    assert tree.node.probability == Decimal.new("0.02")
  end

  test "AND gate probability", %{and_tree: tree} do
    tree = FaultTree.build(tree)
    assert tree.node.probability == Decimal.new("0.0001")
  end

  test "multi level gates", %{or_tree: or_tree} do
    tree = or_tree
    |> FaultTree.add_or_gate("root", "l2")
    |> FaultTree.add_basic("l2", "0.02", "l2_foo")
    |> FaultTree.add_basic("l2", "0.02", "l2_bar")
    |> FaultTree.build()

    assert tree.node.probability == Decimal.new("0.06")
  end
end
