defmodule FaultTree.Parser.XMLTest do
  use ExUnit.Case
  doctest FaultTree.Parser.XML

  @xml_doc """
  <opsa-mef>
    <define-fault-tree name="test">
      <define-gate name="top">
        <or>
          <event name="thing" count="2" />
          <event name="nested" />
        </or>
      </define-gate>

      <define-gate name="nested">
        <or>
          <event name="thing" />
        </or>
      </define-gate>
    </define-fault-tree>

    <model-data>
      <define-basic-event name="thing">
        <float value="0.01" />
      </define-basic-event>
    </model-data>
  </opsa-mef>
  """

  test "parse xml with duplicates" do
    tree = FaultTree.Parser.XML.parse(@xml_doc)
    assert Enum.count(tree.nodes) == 5

    tree = FaultTree.build(tree)
    assert tree.probability == Decimal.new("0.029701")
  end
end
