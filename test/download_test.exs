defmodule DownloadTest do
  use ExUnit.Case

  @project_path System.cwd()

  def test_url(opts) do
    opts = Keyword.put_new(opts, :status, 200)
    query = URI.encode_query(opts)

    "localhost:8089/file?" <> query
  end

  describe "from" do
    test "successfully downloads file" do
      url = test_url(size: 100)
      resulting_download_path = @project_path <> "/" <> (url |> String.split("/") |> List.last())

      File.rm(resulting_download_path)

      assert Download.from(url) == { :ok, resulting_download_path }
      assert file_downloaded_correctly(resulting_download_path, 100)

      File.rm!(resulting_download_path)
    end

    test "files are stored to the specified path" do
      path_to_store = random_tmp_path()

      assert Download.from(test_url(size: 100), [path: path_to_store]) == { :ok, path_to_store }
      assert file_downloaded_correctly(path_to_store, 100)

      File.rm!(path_to_store)
    end

    test "passes for files smaller than max_file_size" do
      path_to_store = random_tmp_path()

      assert Download.from(test_url(size: 200), [path: path_to_store, max_file_size: 201]) == { :ok, path_to_store }
      assert file_downloaded_correctly(path_to_store, 200)

      File.rm!(path_to_store)
    end

    test "rejects for files bigger than max_file_size" do
      path_to_store = random_tmp_path()

      assert Download.from(test_url(size: 200), [path: path_to_store, max_file_size: 199]) == { :error, :file_size_is_too_big }
      refute File.exists?(path_to_store)
    end

    test "does not exceed the size specified by Content-Length" do
      path_to_store = random_tmp_path()

      assert Download.from(test_url(size: 200, content_length: 100), [path: path_to_store, max_file_size: 101]) == { :ok, path_to_store }
      assert file_downloaded_correctly(path_to_store, 100)

      File.rm!(path_to_store)
    end

    test "returns error for non-200 status codes" do
      path_to_store = random_tmp_path()

      assert Download.from(test_url(size: 10, status: 404), [path: path_to_store]) == { :error, 404 }
      refute File.exists?(path_to_store)
    end

    test "returns error for incorrect url" do
      path_to_store = random_tmp_path()

      assert Download.from("http://степан.крут", [path: path_to_store]) == { :error, %HTTPoison.Error{id: nil, reason: :nxdomain} }
      refute File.exists?(path_to_store)
    end

    test "returns error if file exists already" do
      path_to_store = System.cwd() <> "/" <> "mix.exs"

      assert Download.from(test_url(size: 100), [path: path_to_store]) == { :error, :eexist }
    end

    test "aborts if the download takes longer than the given timeout" do
      path_to_store = random_tmp_path()

      assert Download.from(test_url(size: 10, wait: 300), [timeout: 200, path: path_to_store]) == { :error, :timeout }
      refute File.exists?(path_to_store)
    end

    test "does not get interrupted by the flow of messages to the process mailbox" do
      path_to_store = random_tmp_path()

      send self(), :note_to_self

      assert Download.from(test_url(size: 100), [path: path_to_store]) == { :ok, path_to_store }
      assert file_downloaded_correctly(path_to_store, 100)

      receive do
        :note_to_self -> :ok
      after 2_000 ->
        flunk "the message to self() has not been received."
      end
    end
  end

  defp file_downloaded_correctly(path, size) do
    File.exists?(path) && File.stat!(path).size == size
  end

  # Add something for windows os here?
  defp random_tmp_path() do
    hash = :crypto.strong_rand_bytes(30) |> Base.encode16(case: :lower)
    "/tmp/#{hash}"
  end
end
