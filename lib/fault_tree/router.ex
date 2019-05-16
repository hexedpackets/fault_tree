defmodule FaultTree.Router do
  use Trot.Router
  use Trot.Template

  static "/js", "js"

  get "/graph" do
    tree = FaultTree.create(:or)
    |> FaultTree.add_basic("root", "0.01", "foo")
    |> FaultTree.add_basic("root", "0.01", "bar")

    render_template("graph.html.eex", [tree: FaultTree.to_json(tree)])
  end

  import_routes Trot.NotFound
end
