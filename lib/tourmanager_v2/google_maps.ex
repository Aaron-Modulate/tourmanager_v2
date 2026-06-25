defmodule TourmanagerV2.GoogleMaps do
  @moduledoc """
  Server-side Google Maps API client using Req.
  Uses GOOGLE_PLACES_API_KEY for Places, Distance Matrix, and Street View.
  """

  defp api_key, do: System.get_env("GOOGLE_PLACES_API_KEY")

  def search_place(query) when is_binary(query) and query != "" do
    case Req.get("https://maps.googleapis.com/maps/api/place/findplacefromtext/json",
           params: [input: query, inputtype: "textquery", fields: "place_id,name,formatted_address,geometry,photos", key: api_key()]
         ) do
      {:ok, %{status: 200, body: %{"candidates" => [first | _]}}} ->
        {:ok, %{
          place_id: first["place_id"],
          name: first["name"],
          address: first["formatted_address"],
          lat: get_in(first, ["geometry", "location", "lat"]),
          lng: get_in(first, ["geometry", "location", "lng"]),
          photo_ref: get_in(first, ["photos", Access.at(0), "photo_reference"])
        }}

      {:ok, %{status: 200, body: %{"candidates" => []}}} ->
        {:error, :not_found}

      {:ok, %{body: body}} ->
        {:error, body["error_message"] || "Unknown Places API error"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def search_place(_), do: {:error, :empty_query}

  def autocomplete(query, opts \\ [])

  def autocomplete(query, opts) when is_binary(query) and query != "" do
    params =
      [input: query, key: api_key()]
      |> maybe_add_location_bias(opts)

    case Req.get("https://maps.googleapis.com/maps/api/place/autocomplete/json", params: params) do
      {:ok, %{status: 200, body: %{"predictions" => predictions}}} ->
        results =
          predictions
          |> Enum.take(3)
          |> Enum.map(fn p ->
            %{
              place_id: p["place_id"],
              description: p["description"],
              main_text: get_in(p, ["structured_formatting", "main_text"]),
              secondary_text: get_in(p, ["structured_formatting", "secondary_text"])
            }
          end)

        {:ok, results}

      {:ok, %{body: body}} ->
        {:error, body["error_message"] || "Autocomplete API error"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def autocomplete(_, _), do: {:ok, []}

  def place_details(place_id) when is_binary(place_id) do
    case Req.get("https://maps.googleapis.com/maps/api/place/details/json",
           params: [place_id: place_id, fields: "place_id,name,formatted_address,geometry,photos", key: api_key()]
         ) do
      {:ok, %{status: 200, body: %{"result" => result}}} ->
        {:ok, %{
          place_id: result["place_id"],
          name: result["name"],
          address: result["formatted_address"],
          lat: get_in(result, ["geometry", "location", "lat"]),
          lng: get_in(result, ["geometry", "location", "lng"]),
          photo_ref: get_in(result, ["photos", Access.at(0), "photo_reference"])
        }}

      {:ok, %{body: body}} ->
        {:error, body["error_message"] || "Place Details API error"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def place_details(_), do: {:error, :invalid_place_id}

  defp maybe_add_location_bias(params, opts) do
    case {opts[:lat], opts[:lng]} do
      {lat, lng} when is_number(lat) and is_number(lng) ->
        params ++ [location: "#{lat},#{lng}", radius: 50_000]

      _ ->
        params
    end
  end

  def maps_url(%{place_id: place_id}) when is_binary(place_id) do
    "https://www.google.com/maps/place/?q=place_id:#{place_id}"
  end

  def maps_url(%{lat: lat, lng: lng}) when is_number(lat) and is_number(lng) do
    "https://www.google.com/maps/@#{lat},#{lng},17z"
  end

  def maps_url(_), do: nil

  def distance_between(origin, destination) when is_binary(origin) and is_binary(destination) do
    case Req.get("https://maps.googleapis.com/maps/api/distancematrix/json",
           params: [origins: origin, destinations: destination, units: "metric", key: api_key()]
         ) do
      {:ok, %{status: 200, body: body}} ->
        element = get_in(body, ["rows", Access.at(0), "elements", Access.at(0)])

        case element do
          %{"status" => "OK", "distance" => %{"value" => meters}, "duration" => %{"value" => seconds}} ->
            {:ok, %{km: div(meters, 1000), meters: meters, duration_seconds: seconds}}

          %{"status" => "OK", "distance" => %{"value" => meters}} ->
            {:ok, %{km: div(meters, 1000), meters: meters, duration_seconds: nil}}

          _ ->
            {:error, :no_route}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def distance_between(_, _), do: {:error, :invalid_input}

  def directions_url(origin, destination) when is_binary(origin) and is_binary(destination) do
    "https://www.google.com/maps/dir/?api=1&origin=#{URI.encode(origin)}&destination=#{URI.encode(destination)}&travelmode=driving"
  end

  def directions_url(%{origin_address: oa, dest_address: da}) when is_binary(oa) and oa != "" and is_binary(da) and da != "" do
    directions_url(oa, da)
  end

  def directions_url(%{origin: o, destination: d}) when is_binary(o) and is_binary(d) do
    directions_url(o, d)
  end

  def directions_url(_), do: nil

  def search_url(address) when is_binary(address) and address != "" do
    "https://www.google.com/maps/search/#{URI.encode(address)}"
  end

  def search_url(%{venue: v, city: c}) when is_binary(v) and is_binary(c) do
    search_url("#{v}, #{c}")
  end

  def search_url(%{lat: lat, lng: lng}) when is_number(lat) and is_number(lng) do
    "https://www.google.com/maps/search/#{lat},#{lng}"
  end

  def search_url(_), do: nil

  def format_duration(nil), do: nil

  def format_duration(seconds) when is_integer(seconds) do
    hours = div(seconds, 3600)
    mins = div(rem(seconds, 3600), 60)

    cond do
      hours > 0 and mins > 0 -> "~#{hours}h#{String.pad_leading(to_string(mins), 2, "0")}"
      hours > 0 -> "~#{hours}h"
      true -> "~#{mins}m"
    end
  end

  def venue_image_url(place_id) when is_binary(place_id) do
    "https://maps.googleapis.com/maps/api/streetview?size=640x360&location=#{URI.encode(place_id)}&key=#{api_key()}&source=outdoor"
  end

  def venue_image_url(_), do: nil

  def photo_url(photo_reference, max_width \\ 640) when is_binary(photo_reference) do
    "https://maps.googleapis.com/maps/api/place/photo?maxwidth=#{max_width}&photo_reference=#{photo_reference}&key=#{api_key()}"
  end

  def km_to_mi(km) when is_number(km), do: round(km * 0.621371)
  def km_to_mi(_), do: 0

  def format_distance(km, "mi"), do: "#{km_to_mi(km)} mi"
  def format_distance(km, _), do: "#{km} km"

  def format_distance_dual(km) when is_number(km) and km > 0 do
    "#{km} km / #{km_to_mi(km)} mi"
  end

  def format_distance_dual(_), do: nil
end
