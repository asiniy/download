defmodule Download do

  @doc """
  subj.

  Returns:

  * `{ :ok, stored_file_absolute_path }` if everything were ok.
  * `{ :error, :file_size_is_too_big }` if file size exceeds `max_file_size`
  * `{ :error, :download_failure }` if host isn't reachable
  * `{ :error, :eexist }` if file exists already

  Options:

    * `max_file_size` - max available file size for downloading (in bytes). Default is `1024 * 1024 * 1000` (1GB)
    * `path` - absolute file path for the saved file. Default is `pwd <> requested file name`
    * `follow_redirect` - follow HTTP redirects before downloading

  ## Examples

      iex> Download.from("http://speedtest.ftp.otenet.gr/files/test100k.db")
      { :ok, "/absolute/path/to/test_100k.db" }

      iex> Download.from("http://speedtest.ftp.otenet.gr/files/test100k.db", [max_file_size: 99 * 1000])
      { :error, :file_size_is_too_big }

      iex> Download.from("http://speedtest.ftp.otenet.gr/files/test100k.db", [path: "/custom/absolute/file/path.db"])
      { :ok, "/custom/absolute/file/path.db" }

  """

  @default_max_file_size 1024 * 1024 * 1000 # 1 GB

  def from(url, opts \\ []) do
    max_file_size = Keyword.get(opts, :max_file_size, @default_max_file_size)
    file_name = url |> String.split("/") |> List.last()
    path = Keyword.get(opts, :path, get_default_download_path(file_name))
    follow_redirect = Keyword.get(opts, :follow_redirect, false)

    with  { :ok, file } <- create_file(path),
          { :ok, response_parsing_pid } <- create_process(file, max_file_size, path, follow_redirect),
          { :ok, _pid } <- start_download(url, response_parsing_pid, path, follow_redirect),
          { :ok } <- wait_for_download(),
        do: { :ok, path }
  end

  defp get_default_download_path(file_name) do
    System.cwd() <> "/" <> file_name
  end

  defp create_file(path), do: File.open(path, [:write, :exclusive])
  defp create_process(file, max_file_size, path, follow_redirect) do
    opts = %{
      file: file,
      max_file_size: max_file_size,
      controlling_pid: self(),
      path: path,
      downloaded_content_length: 0,
      follow_redirect: follow_redirect
    }
    { :ok, spawn_link(__MODULE__, :do_download, [opts]) }
  end

  defp start_download(url, response_parsing_pid, path, follow_redirect) do
    request = HTTPoison.get url, %{}, stream_to: response_parsing_pid, follow_redirect: follow_redirect

    case request do
      { :error, _reason } ->
        File.rm!(path)
      _ -> nil
    end

    request
  end

  defp wait_for_download() do
    receive do
      reason -> reason
    end
  end

  alias HTTPoison.{AsyncHeaders, AsyncStatus, AsyncChunk, AsyncRedirect, AsyncEnd}

  @wait_timeout 5000

  @doc false
  def do_download(opts) do
    receive do
      response_chunk -> handle_async_response_chunk(response_chunk, opts)
    after
      @wait_timeout -> { :error, :timeout_failure }
    end
  end

  defp handle_async_response_chunk(%AsyncStatus{code: 200}, opts), do: do_download(opts)
  defp handle_async_response_chunk(%AsyncStatus{code: status_code},
                                   opts=%{follow_redirect: follow_redirect})
      when status_code < 400 and status_code >= 300 and follow_redirect do
    do_download(opts)
  end
  defp handle_async_response_chunk(%AsyncStatus{code: status_code}, opts) do
    finish_download({ :error, :unexpected_status_code, status_code }, opts)
  end

  defp handle_async_response_chunk(%AsyncHeaders{headers: headers}, opts) do
    content_length_header = Enum.find(headers, fn({ header_name, _value }) ->
      header_name == "Content-Length"
    end)

    do_handle_content_length(content_length_header, opts)
  end

  defp handle_async_response_chunk(%AsyncChunk{chunk: data}, opts) do
    downloaded_content_length = opts.downloaded_content_length + byte_size(data)

    if downloaded_content_length < opts.max_file_size do
      IO.binwrite(opts.file, data)
      opts_with_content_length_increased = Map.put(opts, :downloaded_content_length, downloaded_content_length)
      do_download(opts_with_content_length_increased)
    else
      finish_download({ :error, :file_size_is_too_big }, opts)
    end
  end

  defp handle_async_response_chunk(%AsyncRedirect{to: new_url}, opts) do
    start_download(new_url, self(), opts.path, opts.follow_redirect)
    do_download(opts)
  end

  defp handle_async_response_chunk(%AsyncEnd{}, opts), do: finish_download({ :ok }, opts)

  # Uncomment one line below if you are prefer to test not "Content-Length" header response, but a real file size
  # defp do_handle_content_length(_, opts), do: do_download(opts)
  defp do_handle_content_length({ "Content-Length", content_length }, opts) do
    if String.to_integer(content_length) > opts.max_file_size do
      finish_download({ :error, :file_size_is_too_big }, opts)
    else
      do_download(opts)
    end
  end
  defp do_handle_content_length(nil, opts), do: do_download(opts)

  defp finish_download(reason, opts) do
    File.close(opts.file)
    if (elem(reason, 0) == :error) do
      File.rm!(opts.path)
    end
    send(opts.controlling_pid, reason)
  end

end
