class Api::V1::Webhooks::StripeController < ApplicationController
  include StructuredLogging

  SIGNATURE_ERROR_MSG = "Stripe Webhook Signature Verification Failed. This indicates a possible malicious attack or an expired/incorrect STRIPE_WEBHOOK_SECRET environment variable."

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      log_event("stripe_webhook_parser_error", level: :warn, payload: { message: e.message })
      head :bad_request and return
    rescue Stripe::SignatureVerificationError => e
      report_exception(e, custom_message: SIGNATURE_ERROR_MSG)
      head :bad_request and return
    end

    ProcessStripeWebhookJob.perform_later(
      event_type: event.type,
      object_json: event.data.object.to_json
    )

    head :ok
  end
end
