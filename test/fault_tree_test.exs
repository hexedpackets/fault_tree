defmodule FaultTreeTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
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

  test "ATLEAST can only have a single child" do
    tree = FaultTree.create(:atleast)
    |> FaultTree.add_basic("root", "0.01", "foo")

    capture_log(fn ->
      assert FaultTree.add_basic(tree, "root", "0.01", "bar") == {:error, :invalid}
    end)
  end

  test "OR gate probability", %{or_tree: tree} do
    tree = FaultTree.build(tree)
    assert tree.node.probability == Decimal.new("0.0199")
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

    assert tree.node.probability == Decimal.new("0.05871196")
  end

  test "ATLEAST gate probability" do
    tree = %FaultTree.Node{type: :atleast, id: 0, name: "root", atleast: {2, 3}}
    |> FaultTree.create()
    |> FaultTree.add_basic("root", "0.01", "foo")
    |> FaultTree.build()

    assert tree.node.probability == Decimal.new("0.0001495")
  end

  test "names of nodes are unique", %{or_tree: tree} do
    new = FaultTree.validate_name(tree, %{name: "jimjamjon"})
    old = FaultTree.validate_name(tree, %{name: "root"})

    assert elem(new, 0)  == :ok
    assert elem(old, 0)  == :error
  end
end
