defmodule TourmanagerV2Web.StripeWebhookController do
  use TourmanagerV2Web, :controller

  alias TourmanagerV2.Billing

  def webhook(conn, _params) do
    payload = conn.assigns[:raw_body]
    signature = Plug.Conn.get_req_header(conn, "stripe-signature") |> List.first()

    case Billing.verify_webhook(payload, signature) do
      {:ok, %{"type" => "checkout.session.completed", "data" => %{"object" => session}}} ->
        Billing.handle_checkout_completed(session)
        json(conn, %{ok: true})

      {:ok, %{"type" => "customer.subscription.updated", "data" => %{"object" => subscription}}} ->
        Billing.handle_subscription_updated(subscription)
        json(conn, %{ok: true})

      {:ok, %{"type" => "customer.subscription.deleted", "data" => %{"object" => subscription}}} ->
        Billing.handle_subscription_deleted(subscription)
        json(conn, %{ok: true})

      {:ok, _event} ->
        json(conn, %{ok: true})

      {:error, _reason} ->
        conn |> put_status(400) |> json(%{error: "Invalid webhook"})
    end
  end
end
