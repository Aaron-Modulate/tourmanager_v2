# Clears all user/event/tour assignment records without touching core data.
# Run via: mix run scripts/clear_assignments.exs

alias Tourmanager.Repo
import Ecto.Query

tables = [
  "events_users",        # user ↔ event
  "tour_members",        # user ↔ tour
  "gig_members",         # user ↔ gig
  "tour_invites",        # pending email invites
  "user_collaborators"   # historical pairings
]

for table <- tables do
  {count, _} = Repo.delete_all(table)
  IO.puts("#{table}: #{count} rows deleted")
end

IO.puts("\nDone.")
