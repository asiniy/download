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

  ## Examples

      iex> Download.from("http://speedtest.ftp.otenet.gr/files/test100k.db")
      { :ok, "/absolute/path/to/test_100k.db" }

      iex> Download.from("http://speedtest.ftp.otenet.gr/files/test100k.db", [max_file_size: 99 * 1000])
      { :error, :file_size_is_too_big }

      iex> Download.from("http://speedtest.ftp.otenet.gr/files/test100k.db", [path: "/custom/absolute/file/path.db"])
      { :ok, "/custom/absolute/file/path.db" }

  """

  @default_max_file_size 1024 * 1024 * 1000 # 1 GB
  @default_timeout 2 * 60 * 1000 # 2 minutes

  def from(url, opts \\ []) do
    max_file_size = Keyword.get(opts, :max_file_size, @default_max_file_size)
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    path = Keyword.get(opts, :path, default_download_path(url))

    with  { :ok, io_device } <- open_file_for_writing(path),
          download_task <- Task.async(fn ->
            download(url, io_device, path, max_file_size)
          end),
          :ok <- Task.await(download_task, timeout),
        do: { :ok, path }
  end

  defp default_download_path(url) do
    filename = url |> String.split("/") |> List.last()
    Path.join(System.cwd(), filename)
  end

  defp open_file_for_writing(path),
    do: File.open(path, [:write, :exclusive])

  defp download(url, io_device, path, max_file_size) do
    request = HTTPoison.get(url, %{}, stream_to: self())

    case request do
      {:ok, _} ->
        opts = %{
          io_device: io_device,
          max_file_size: max_file_size,
          path: path,
          downloaded_size: 0
        }

        do_download(opts)
      {:error, _} = error ->
        File.rm!(path)
        error
    end
  end

  alias HTTPoison.{AsyncHeaders, AsyncStatus, AsyncChunk, AsyncEnd}

  def do_download(opts) do
    receive do
      %AsyncStatus{code: 200} ->
        do_download(opts)
      %AsyncStatus{code: error_code} ->
        finish_download({ :error, error_code }, opts)
      %AsyncHeaders{headers: headers} ->
        check_content_length(headers, opts)
      %AsyncChunk{chunk: data} ->
        write_chunk(data, opts)
      %AsyncEnd{} ->
        finish_download(:ok, opts)
    end
  end

  defp check_content_length(%{"Content-Length" => content_length}, opts) do
    if String.to_integer(content_length) > opts.max_file_size do
      finish_download({ :error, :file_size_is_too_big }, opts)
    else
      do_download(opts)
    end
  end
  defp check_content_length(_headers, opts), do: do_download(opts)

  defp write_chunk(data, opts) do
    downloaded_size = opts.downloaded_size + byte_size(data)

    if downloaded_size < opts.max_file_size do
      IO.binwrite(opts.io_device, data)
      opts |> Map.put(:downloaded_size, downloaded_size) |> do_download()
    else
      finish_download({ :error, :file_size_is_too_big }, opts)
    end
  end

  defp finish_download(:ok, %{io_device: io_device}) do
    File.close(io_device)
  end
  defp finish_download(error, %{io_device: io_device, path: path}) do
    File.close(io_device)
    File.rm!(path)
    error
  end
end
