defmodule TourmanagerV2.Production.DocumentsTest do
  use TourmanagerV2.DataCase, async: true

  import TourmanagerV2.ProductionFixtures

  alias TourmanagerV2.Production.Documents

  describe "create_document/3" do
    test "creates a document with valid attrs" do
      ws = workspace_fixture()
      venue = venue_fixture(ws)
      user = user_fixture()

      assert {:ok, doc} = Documents.create_document(venue.id, user.id, %{
        "title" => "Main Stage Rigging Plot",
        "document_type" => "rigging_plot",
        "file_url" => "https://storage.example.com/doc.pdf"
      })

      assert doc.title == "Main Stage Rigging Plot"
      assert doc.document_type == "rigging_plot"
      assert doc.venue_id == venue.id
      assert doc.uploaded_by_user_id == user.id
      assert doc.uploaded_at != nil
    end

    test "requires title" do
      ws = workspace_fixture()
      venue = venue_fixture(ws)
      user = user_fixture()

      assert {:error, cs} = Documents.create_document(venue.id, user.id, %{})
      assert cs.errors[:title]
    end
  end

  describe "delete_document/2" do
    test "uploader can delete their document" do
      ws = workspace_fixture()
      venue = venue_fixture(ws)
      user = user_fixture()
      doc = production_document_fixture(venue, user)

      assert {:ok, _} = Documents.delete_document(doc.id, user.id)
      assert Documents.list_documents_for_venue(venue.id) == []
    end

    test "platform admin can delete any document" do
      venue = venue_fixture()
      uploader = user_fixture()
      admin = TourmanagerV2.Repo.update!(Ecto.Changeset.change(user_fixture(), is_admin: true))

      doc = production_document_fixture(venue, uploader)
      assert {:ok, _} = Documents.delete_document(doc.id, admin.id)
    end

    test "unrelated user cannot delete a document" do
      ws = workspace_fixture()
      venue = venue_fixture(ws)
      uploader = user_fixture()
      other = user_fixture()

      doc = production_document_fixture(venue, uploader)
      assert {:error, :unauthorized} = Documents.delete_document(doc.id, other.id)
    end
  end

  describe "list_documents_for_venue/1" do
    test "returns all documents with uploader preloaded" do
      ws = workspace_fixture()
      venue = venue_fixture(ws)
      user = user_fixture()
      d1 = production_document_fixture(venue, user, title: "Doc 1")
      d2 = production_document_fixture(venue, user, title: "Doc 2")

      docs = Documents.list_documents_for_venue(venue.id)
      ids = Enum.map(docs, & &1.id)
      assert d1.id in ids
      assert d2.id in ids
      assert Enum.all?(docs, fn d -> d.uploaded_by_user != nil end)
    end
  end

  describe "group_by_type/1" do
    test "groups documents by document_type" do
      ws = workspace_fixture()
      venue = venue_fixture(ws)
      user = user_fixture()
      production_document_fixture(venue, user, document_type: "rigging_plot")
      production_document_fixture(venue, user, document_type: "rigging_plot")
      production_document_fixture(venue, user, document_type: "tech_pack")

      docs = Documents.list_documents_for_venue(venue.id)
      grouped = Documents.group_by_type(docs)

      assert length(grouped["rigging_plot"]) == 2
      assert length(grouped["tech_pack"]) == 1
    end
  end
end
