defmodule TourmanagerV2.TourBroadcast do
  @moduledoc """
  PubSub broadcasts for tour data changes. When any client modifies
  tour data (routes, gigs, etc.), all other connected clients viewing
  that tour receive a reload signal.
  """

  @pubsub TourmanagerV2.PubSub

  def topic(tour_id) when is_binary(tour_id), do: "tour:#{tour_id}"
  def topic(_), do: nil

  def subscribe(tour_id) when is_binary(tour_id) do
    Phoenix.PubSub.subscribe(@pubsub, topic(tour_id))
  end

  def subscribe(_), do: :ok

  def unsubscribe(tour_id) when is_binary(tour_id) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(tour_id))
  end

  def unsubscribe(_), do: :ok

  def broadcast_change(tour_id, source_pid \\ self()) when is_binary(tour_id) do
    Phoenix.PubSub.broadcast(@pubsub, topic(tour_id), {:tour_data_changed, tour_id, source_pid})
  end
end
