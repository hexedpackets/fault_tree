defmodule FaultTree.Router do
  use Trot.Router
  use Trot.Template

  static "/js", "js"

  get "/" do
    render_template("upload.html.eex", [])
  end

  post "/analyze" do
    tree = conn.body_params
    |> Map.get("contents")
    |> FaultTree.parse()
    |> FaultTree.to_json()

    case Map.get(conn.body_params, "output") do
      "json" -> tree
      "html" -> render_template("graph.html.eex", [tree: tree])
      _ -> :bad_request
    end
  end

  import_routes Trot.NotFound
end
