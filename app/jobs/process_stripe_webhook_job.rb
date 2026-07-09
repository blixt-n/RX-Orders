class ProcessStripeWebhookJob < ApplicationJob
  include StructuredLogging
  queue_as :default

  def perform(event_type:, object_json:)
    stripe_object = JSON.parse(object_json)
    order_id = stripe_object.dig("metadata", "order_id")

    if order_id.blank?
      log_event("stripe_webhook_ignored", level: :info, payload: { event_type: event_type })
      return
    end

    order = Order.find(order_id)

    case event_type
    when "payment_intent.succeeded"
      order.paid! unless order.paid?
    when "payment_intent.payment_failed"
      order.failed! unless order.failed?
    else
      log_event("unhandled_stripe_event_type", payload: { event_type: event_type, order_id: order.id })
    end
  end
end
