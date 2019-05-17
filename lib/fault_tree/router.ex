defmodule FaultTree.Router do
  use Trot.Router
  use Trot.Template

  static "/js", "js"

  get "/graph" do
    tree = FaultTree.create(:or)
    |> FaultTree.add_basic("root", "0.01", "foo")
    |> FaultTree.add_basic("root", "0.01", "bar")
    |> FaultTree.add_or_gate("root", "layer2")
    |> FaultTree.add_transfer("layer2", "foo")

    render_template("graph.html.eex", [tree: FaultTree.to_json(tree)])
  end

  import_routes Trot.NotFound
end
