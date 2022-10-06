defmodule DownloadTest do
  use ExUnit.Case

  @remote_file_url "http://speedtest.ftp.otenet.gr/files/test100k.db"
  @remote_file_size 1024 * 100

  @project_path File.cwd!()

  describe "from" do
    test "successfully downloads file" do
      resulting_download_path = @project_path <> "/" <> "test100k.db"

      File.rm(resulting_download_path)

      assert Download.from(@remote_file_url) == { :ok, resulting_download_path }
      assert file_downloaded_correctly(resulting_download_path)

      File.rm!(resulting_download_path)
    end

    test "files are stored to the specified path" do
      path_to_store = random_tmp_path()

      assert Download.from(@remote_file_url, [path: path_to_store]) == { :ok, path_to_store }
      assert file_downloaded_correctly(path_to_store)
    end

    test "passes for files smaller than max_file_size" do
      path_to_store = random_tmp_path()

      assert Download.from(@remote_file_url, [path: path_to_store, max_file_size: 101 * 1024]) == { :ok, path_to_store }
      assert file_downloaded_correctly(path_to_store)
    end

    test "rejects for files bigger than max_file_size" do
      path_to_store = random_tmp_path()

      assert Download.from(@remote_file_url, [path: path_to_store, max_file_size: 99 * 1024]) == { :error, :file_size_is_too_big }
      refute File.exists?(path_to_store)
    end

    test "returns error for redirecting url" do
      path_to_store = random_tmp_path()

      assert Download.from("https://github.com/tzusman/GCM-v3/eee", [path: path_to_store]) == { :error, :unexpected_status_code, 404 }
      refute File.exists?(path_to_store)
    end

    test "returns error for incorrect url" do
      path_to_store = random_tmp_path()

      assert Download.from("http://степан.крут", [path: path_to_store]) == { :error, %HTTPoison.Error{id: nil, reason: :nxdomain} }
      refute File.exists?(path_to_store)
    end

    test "returns error if file exists already" do
      path_to_store = File.cwd!() <> "/" <> "mix.exs"

      assert Download.from(@remote_file_url, [path: path_to_store]) == { :error, :eexist }
    end
  end

  defp file_downloaded_correctly(path) do
    File.exists?(path) && File.stat!(path).size == @remote_file_size
  end

  # Add something for windows os here?
  defp random_tmp_path() do
    hash = :crypto.strong_rand_bytes(30) |> Base.encode16(case: :lower)
    "/tmp/#{hash}"
  end
end
