defmodule TourmanagerV2.Admin.Scheduler do
  use GenServer
  require Logger

  @check_interval :timer.minutes(15)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    schedule_check()
    {:ok, state}
  end

  def handle_info(:check_jobs, state) do
    run_due_jobs()
    schedule_check()
    {:noreply, state}
  end

  defp schedule_check do
    Process.send_after(self(), :check_jobs, @check_interval)
  end

  defp run_due_jobs do
    alias TourmanagerV2.Admin

    try do
      jobs = Admin.list_jobs()

      Enum.each(jobs, fn job ->
        if job.enabled && due?(job) do
          Logger.info("Scheduler: running #{job.name}")

          case Admin.run_job(job.name) do
            {:ok, _} -> Logger.info("Scheduler: #{job.name} completed")
            {:error, reason} -> Logger.warning("Scheduler: #{job.name} failed: #{inspect(reason)}")
          end
        end
      end)
    rescue
      e -> Logger.warning("Scheduler check failed: #{Exception.message(e)}")
    end
  end

  defp due?(%{last_run_at: nil}), do: true

  defp due?(%{last_run_at: last_run, cron_expression: cron}) do
    interval_seconds = parse_cron_interval(cron)
    DateTime.diff(DateTime.utc_now(), last_run, :second) >= interval_seconds
  end

  defp parse_cron_interval(cron) do
    case String.split(cron, " ") do
      [_min, hour_part, _, _, _] ->
        case Regex.run(~r/\*\/(\d+)/, hour_part) do
          [_, hours] -> String.to_integer(hours) * 3600
          _ -> 6 * 3600
        end

      _ ->
        6 * 3600
    end
  end
end
