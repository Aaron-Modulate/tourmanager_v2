defmodule TourmanagerV2.Admin do
  import Ecto.Query
  alias TourmanagerV2.Repo
  alias TourmanagerV2.Admin.Job

  def list_jobs do
    Job |> order_by(asc: :name) |> Repo.all()
  end

  def get_job!(id), do: Repo.get!(Job, id)

  def get_or_create_job(name) do
    case Repo.get_by(Job, name: name) do
      nil ->
        %Job{}
        |> Job.changeset(%{name: name, cron_expression: "0 */6 * * *"})
        |> Repo.insert!()

      job ->
        job
    end
  end

  def update_job(%Job{} = job, attrs) do
    job
    |> Job.changeset(attrs)
    |> Repo.update()
  end

  def run_job("stripe_sync_pricing") do
    case TourmanagerV2.Billing.fetch_stripe_pricing() do
      {:ok, data} ->
        job = get_or_create_job("stripe_sync_pricing")

        update_job(job, %{
          last_run_at: DateTime.utc_now(),
          last_result: Jason.encode!(data)
        })

        {:ok, data}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def run_job(_), do: {:error, :unknown_job}
end
