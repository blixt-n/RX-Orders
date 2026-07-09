class StripeCheckout
  include StructuredLogging

  GATEWAY_UNAVAILABLE_MSG = "Payment gateway temporarily unavailable. Please try again shortly.".freeze
  GENERIC_SYSTEM_ERROR_MSG = "An unexpected error occurred while processing your payment.".freeze

  def initialize(order)
    @order = order
  end

  def call
    intent = STRIPE_CIRCUIT.run { stripe_payment_intent }

    @order.update!(
      stripe_payment_intent_id: intent.id,
      status: :processing
    )

    log_event("stripe_checkout_initiated", payload: { order_id: @order.id, intent_id: intent.id })
    { success: true, client_secret: intent.client_secret }

  rescue Circuitbox::OpenCircuitError => e
    report_exception(e, custom_message: "Stripe circuit breaker is OPEN. API is completely unreachable.")
    { success: false, error: GATEWAY_UNAVAILABLE_MSG }

  rescue ActiveRecord::RecordInvalid => e
    report_exception(e, custom_message: "Failed to update order status to processing.", payload: { order_id: @order.id })
    { success: false, error: GENERIC_SYSTEM_ERROR_MSG }

  rescue Stripe::StripeError => e
    report_exception(e, custom_message: "Critical Stripe API System Failure", payload: { order_id: @order.id })
    { success: false, error: GENERIC_SYSTEM_ERROR_MSG }
  end

  private

  def idempotency_key
    "order_#{@order.id}_payment_intent"
  end

  def stripe_payment_intent
    @stripe_payment_intent ||= Stripe::PaymentIntent.create(
      {
        amount: @order.total_cents,
        currency: "usd",
        metadata: { order_id: @order.id }
      },
      { idempotency_key: idempotency_key }
    )
  end
end
