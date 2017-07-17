ExUnit.start()

defmodule TestServer do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn = fetch_query_params(conn)

    resp_size = parse_numeric(conn.query_params["size"])
    resp_status = parse_numeric(conn.query_params["status"])
    body = :binary.copy(<<0>>, resp_size)

    content_length = conn.query_params["content_length"]
    conn = if content_length,
      do: put_resp_header(conn, "content-length", content_length),
      else: conn

    send_resp(conn, resp_status, body)
  end

  defp parse_numeric(binary), do: binary |> Integer.parse() |> elem(0)
end

{:ok, _} = Plug.Adapters.Cowboy.http(TestServer, [], port: 8089)
