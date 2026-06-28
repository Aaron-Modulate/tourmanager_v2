defmodule TourmanagerV2.Storage do
  @moduledoc false

  def upload(path, content, content_type) do
    bucket = bucket_name()

    ExAws.S3.put_object(bucket, path, content, content_type: content_type, acl: :public_read)
    |> ExAws.request()
    |> case do
      {:ok, _} -> {:ok, public_url(path)}
      error -> error
    end
  end

  def delete(path) do
    ExAws.S3.delete_object(bucket_name(), path)
    |> ExAws.request()
  end

  def public_url(path) do
    endpoint = Application.get_env(:ex_aws, :s3, [])
    scheme = Keyword.get(endpoint, :scheme, "https://")
    host = Keyword.get(endpoint, :host, "fly.storage.tigris.dev")
    bucket = bucket_name()

    "#{scheme}#{bucket}.#{host}/#{path}"
  end

  defp bucket_name do
    Application.get_env(:tourmanager_v2, :storage, [])
    |> Keyword.get(:bucket, "tourmanager-uploads")
  end
end
