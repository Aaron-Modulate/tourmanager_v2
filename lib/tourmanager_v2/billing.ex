defmodule TourmanagerV2.Billing do
  alias TourmanagerV2.Repo
  alias TourmanagerV2.Accounts.User

  @base_seats 10
  @base_price_cents 4900
  @extra_seat_cents 200

  def base_seats, do: @base_seats

  def calculate_price(seats) when is_integer(seats) and seats >= @base_seats do
    @base_price_cents + (seats - @base_seats) * @extra_seat_cents
  end

  def calculate_price(_), do: @base_price_cents

  def format_price(cents) do
    dollars = div(cents, 100)
    remainder = rem(cents, 100)
    "$#{dollars}.#{String.pad_leading(to_string(remainder), 2, "0")} NZD"
  end

  def price_breakdown(seats) when is_integer(seats) do
    seats = max(seats, @base_seats)
    extra = seats - @base_seats
    total = @base_price_cents + extra * @extra_seat_cents

    %{
      base: format_price(@base_price_cents),
      extra_seats: extra,
      extra_cost: if(extra > 0, do: format_price(extra * @extra_seat_cents)),
      total: format_price(total),
      total_cents: total
    }
  end

  def fetch_stripe_pricing do
    price_id = current_price_id()

    case stripe_get("/v1/prices/#{price_id}") do
      {:ok, price} ->
        product_id = price["product"]
        product_data = case stripe_get("/v1/products/#{product_id}") do
          {:ok, prod} -> %{name: prod["name"], description: prod["description"]}
          _ -> %{name: nil, description: nil}
        end

        {:ok, %{
          price_id: price["id"],
          unit_amount: price["unit_amount"],
          currency: price["currency"],
          type: price["type"],
          recurring: price["recurring"],
          product: product_data,
          tiers: price["tiers"],
          billing_scheme: price["billing_scheme"],
          fetched_at: DateTime.utc_now() |> DateTime.to_iso8601()
        }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp secret_key, do: System.get_env("STRIPE_SECRET_KEY")
  defp current_price_id, do: System.get_env("STRIPE_PRICE_ID")
  defp webhook_secret, do: System.get_env("STRIPE_WEBHOOK_SECRET")

  def webhook_secret!, do: webhook_secret()

  def create_checkout_session(%User{} = user, seats) when is_integer(seats) and seats >= @base_seats do
    customer_id = ensure_stripe_customer(user)
    price_id = current_price_id()

    params = %{
      "customer" => customer_id,
      "mode" => "subscription",
      "line_items[0][price]" => price_id,
      "line_items[0][quantity]" => to_string(seats),
      "success_url" => success_url(),
      "cancel_url" => cancel_url(),
      "metadata[user_id]" => user.id,
      "metadata[seats]" => to_string(seats),
      "metadata[price_id]" => price_id
    }

    result = stripe_post("/v1/checkout/sessions", params)

    case result do
      {:ok, %{"id" => session_id, "url" => url}} ->
        {:ok, %{session_id: session_id, url: url}}

      {:ok, %{"error" => %{"message" => msg}}} ->
        require Logger
        Logger.error("Stripe checkout error: #{msg}")
        {:error, msg}

      {:ok, other} ->
        require Logger
        Logger.error("Stripe checkout unexpected response: #{inspect(other)}")
        msg = get_in(other, ["error", "message"]) || inspect(other)
        {:error, msg}

      {:error, reason} ->
        require Logger
        Logger.error("Stripe checkout request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def handle_checkout_completed(session) do
    user_id = get_in(session, ["metadata", "user_id"])
    seats_str = get_in(session, ["metadata", "seats"])
    price_id = get_in(session, ["metadata", "price_id"])
    subscription_id = session["subscription"]
    customer_id = session["customer"]

    if user_id do
      user = Repo.get!(User, user_id)
      seats_int = if seats_str, do: String.to_integer(seats_str), else: @base_seats

      period_end = fetch_subscription_period_end(subscription_id)

      user
      |> User.changeset(%{
        plan: "paid",
        role: "manager",
        crew_seats: seats_int,
        stripe_customer_id: customer_id,
        stripe_subscription_id: subscription_id,
        stripe_price_id: price_id,
        subscription_quantity: seats_int,
        subscription_status: "active",
        subscription_period_end: period_end,
        cancelled_at: nil
      })
      |> Repo.update()
    else
      {:error, :no_user_id}
    end
  end

  def handle_subscription_updated(subscription) do
    sub_id = subscription["id"]
    cancel_at_period_end = subscription["cancel_at_period_end"]
    status = subscription["status"]

    case Repo.get_by(User, stripe_subscription_id: sub_id) do
      nil ->
        {:error, :user_not_found}

      user ->
        attrs =
          cond do
            cancel_at_period_end == true ->
              period_end =
                if subscription["current_period_end"] do
                  DateTime.from_unix!(subscription["current_period_end"])
                end

              %{
                subscription_status: "cancelling",
                subscription_period_end: period_end,
                cancelled_at: DateTime.utc_now()
              }

            status == "active" && !cancel_at_period_end ->
              quantity =
                case get_in(subscription, ["items", "data"]) do
                  [%{"quantity" => q} | _] -> q
                  _ -> user.subscription_quantity
                end

              %{
                subscription_status: "active",
                subscription_quantity: quantity,
                cancelled_at: nil,
                subscription_period_end:
                  if(subscription["current_period_end"],
                    do: DateTime.from_unix!(subscription["current_period_end"]),
                    else: user.subscription_period_end
                  )
              }

            true ->
              %{}
          end

        if attrs != %{} do
          user |> User.changeset(attrs) |> Repo.update()
        else
          {:ok, user}
        end
    end
  end

  def handle_subscription_deleted(subscription) do
    sub_id = subscription["id"]

    case Repo.get_by(User, stripe_subscription_id: sub_id) do
      nil ->
        {:error, :user_not_found}

      user ->
        user
        |> User.changeset(%{
          plan: "free",
          role: "crew",
          subscription_status: "cancelled"
        })
        |> Repo.update()
    end
  end

  def cancel_subscription(%User{stripe_subscription_id: sub_id}) when is_binary(sub_id) and sub_id != "" do
    case stripe_post("/v1/subscriptions/#{sub_id}", %{"cancel_at_period_end" => "true"}) do
      {:ok, %{"id" => _id, "cancel_at_period_end" => true}} ->
        :ok

      {:ok, %{"error" => %{"message" => msg}}} ->
        {:error, msg}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def cancel_subscription(_), do: {:error, :no_subscription}

  defp fetch_subscription_period_end(nil), do: nil

  defp fetch_subscription_period_end(sub_id) do
    case stripe_get("/v1/subscriptions/#{sub_id}") do
      {:ok, %{"current_period_end" => ts}} when is_integer(ts) ->
        DateTime.from_unix!(ts)

      _ ->
        nil
    end
  end

  defp ensure_stripe_customer(%User{stripe_customer_id: cid}) when is_binary(cid) and cid != "", do: cid

  defp ensure_stripe_customer(%User{} = user) do
    case stripe_post("/v1/customers", %{"email" => user.email, "name" => user.name, "metadata[user_id]" => user.id}) do
      {:ok, %{"id" => customer_id}} ->
        user
        |> User.changeset(%{stripe_customer_id: customer_id})
        |> Repo.update!()

        customer_id

      _ ->
        raise "Failed to create Stripe customer"
    end
  end

  defp stripe_post(path, params) do
    case Req.post("https://api.stripe.com" <> path,
           form: params,
           headers: [{"authorization", "Bearer #{secret_key()}"}]
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %{body: body}} ->
        {:error, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp stripe_get(path) do
    case Req.get("https://api.stripe.com" <> path,
           headers: [{"authorization", "Bearer #{secret_key()}"}]
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %{body: body}} ->
        {:error, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp success_url do
    base = System.get_env("PHX_HOST") || "localhost:4000"
    scheme = if System.get_env("PHX_HOST"), do: "https", else: "http"
    "#{scheme}://#{base}/?billing=success"
  end

  defp cancel_url do
    base = System.get_env("PHX_HOST") || "localhost:4000"
    scheme = if System.get_env("PHX_HOST"), do: "https", else: "http"
    "#{scheme}://#{base}/?billing=cancelled"
  end

  def verify_webhook(payload, signature) do
    construct_event(payload, signature)
  end

  defp construct_event(payload, signature) do
    secret = webhook_secret()

    parts =
      signature
      |> String.split(",")
      |> Enum.map(fn part ->
        [k, v] = String.split(part, "=", parts: 2)
        {String.trim(k), String.trim(v)}
      end)
      |> Map.new()

    timestamp = parts["t"]
    sig_v1 = parts["v1"]

    if timestamp && sig_v1 do
      signed_payload = "#{timestamp}.#{payload}"
      expected = :crypto.mac(:hmac, :sha256, secret, signed_payload) |> Base.encode16(case: :lower)

      if Plug.Crypto.secure_compare(expected, sig_v1) do
        {:ok, Jason.decode!(payload)}
      else
        {:error, :invalid_signature}
      end
    else
      {:error, :missing_signature_parts}
    end
  end
end
