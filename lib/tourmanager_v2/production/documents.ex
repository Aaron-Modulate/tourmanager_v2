defmodule TourmanagerV2.Production.Documents do
  @moduledoc """
  Context for managing production documents (tech packs, rigging plots, etc.).

  # TODO: Add extract_metadata/1 here when AI extraction is implemented.
  """

  import Ecto.Query
  alias TourmanagerV2.Repo
  alias TourmanagerV2.Production.ProductionDocument
  alias TourmanagerV2.Accounts.User

  @spec list_documents_for_venue(binary()) :: [ProductionDocument.t()]
  def list_documents_for_venue(venue_id) do
    Repo.all(
      from d in ProductionDocument,
        where: d.venue_id == ^venue_id,
        order_by: [d.document_type, desc: d.inserted_at],
        preload: [:uploaded_by_user]
    )
  end

  @spec get_document!(binary()) :: ProductionDocument.t()
  def get_document!(id), do: Repo.get!(ProductionDocument, id)

  @spec create_document(binary(), binary(), map()) ::
          {:ok, ProductionDocument.t()} | {:error, Ecto.Changeset.t()}
  def create_document(venue_id, user_id, attrs) do
    attrs = Map.put(attrs, "uploaded_at", DateTime.utc_now() |> DateTime.truncate(:second))

    %ProductionDocument{venue_id: venue_id, uploaded_by_user_id: user_id}
    |> ProductionDocument.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a document. Only the original uploader or a platform admin may delete.
  """
  @spec delete_document(binary(), binary()) ::
          {:ok, ProductionDocument.t()} | {:error, :unauthorized} | {:error, Ecto.Changeset.t()}
  def delete_document(document_id, user_id) do
    doc = Repo.get!(ProductionDocument, document_id)

    if doc.uploaded_by_user_id == user_id or platform_admin?(user_id) do
      Repo.delete(doc)
    else
      {:error, :unauthorized}
    end
  end

  @spec group_by_type([ProductionDocument.t()]) :: map()
  def group_by_type(documents) do
    Enum.group_by(documents, & &1.document_type)
  end

  @spec change_document(ProductionDocument.t(), map()) :: Ecto.Changeset.t()
  def change_document(%ProductionDocument{} = doc, attrs \\ %{}) do
    ProductionDocument.changeset(doc, attrs)
  end

  defp platform_admin?(user_id) do
    case Repo.get(User, user_id) do
      %User{is_admin: true} -> true
      _ -> false
    end
  end
end
