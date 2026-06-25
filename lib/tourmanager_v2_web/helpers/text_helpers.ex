defmodule TourmanagerV2Web.TextHelpers do
  @moduledoc """
  Shared text formatting helpers used across components and LiveViews.
  """

  def initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  def initials(_), do: "?"
end
