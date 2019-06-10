defmodule Router do
  @moduledoc """
  Router
  module describes web functions GET, POST
  """

	use Plug.Router

	plug :match
	plug :dispatch
  plug Plug.Static, at: "/", from: :kvstore

  get "/" do
    conn = put_resp_content_type(conn, "text/html")
    send_file(conn, 200, "www/index.html")
  end

  get "get_table" do
    result = Storage.get_table()
    send_resp(conn, 200, Poison.encode!(result))
  end

  post ":json" do
    result = case Poison.decode!(json) do
      ["update", key, value, ttl] -> Storage.update(key, value, ttl);
      ["delete", key] -> Storage.delete(key);
      _ -> "undefined"
    end
    send_resp(conn, 200, result)
  end

  match _ do
    send_resp(conn, 404, "404 error not found!")
  end
end

