defmodule FaultTree.Router do
  @moduledoc """
  Handler for HTTP requests.
  """

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
      "json" -> {200, tree, %{"Content-Type": "application/json"}}
      "html" -> render_template("graph.html.eex", [tree: tree])
      _ -> :bad_request
    end
  end

  import_routes Trot.NotFound
end
