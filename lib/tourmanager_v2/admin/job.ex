defmodule TourmanagerV2.Admin.Job do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "admin_jobs" do
    field :name, :string
    field :cron_expression, :string, default: "0 */6 * * *"
    field :enabled, :boolean, default: true
    field :last_run_at, :utc_datetime
    field :last_result, :string

    timestamps()
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [:name, :cron_expression, :enabled, :last_run_at, :last_result])
    |> validate_required([:name, :cron_expression])
    |> unique_constraint(:name)
    |> validate_cron()
  end

  defp validate_cron(changeset) do
    case get_field(changeset, :cron_expression) do
      nil -> changeset
      expr ->
        parts = String.split(expr, " ")
        if length(parts) == 5, do: changeset, else: add_error(changeset, :cron_expression, "must have 5 fields")
    end
  end
end
