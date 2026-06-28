defmodule TourmanagerV2.Touring.Setlist do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @sources ~w(manual upload ocr)
  @ocr_statuses ~w(none pending processing complete failed)

  schema "setlists" do
    field :name, :string
    field :source, :string, default: "manual"
    field :is_tour_default, :boolean, default: false
    field :date, :date
    field :file_url, :string
    field :file_type, :string
    field :ocr_status, :string, default: "none"

    belongs_to :tour, TourmanagerV2.Touring.Tour
    belongs_to :uploaded_by, TourmanagerV2.Accounts.User
    has_many :items, TourmanagerV2.Touring.SetlistItem, preload_order: [asc: :position]

    timestamps()
  end

  def changeset(setlist, attrs) do
    setlist
    |> cast(attrs, [:name, :source, :is_tour_default, :date, :file_url, :file_type, :ocr_status])
    |> validate_required([:name])
    |> validate_inclusion(:source, @sources)
    |> validate_inclusion(:ocr_status, @ocr_statuses)
  end
end
