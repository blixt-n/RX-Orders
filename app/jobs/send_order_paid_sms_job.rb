class SendOrderPaidSmsJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order&.buyer&.phone_number

    message = "Great news! Your order ##{order.id} has been paid and is now being processed."

    client = TwilioClient.new
    result = client.send_sms(phone_number: order.buyer.phone_number, body: message)

    if !result[:success] && result[:error] == TwilioClient::SERVICE_UNAVAILABLE_MSG
      raise "Twilio service unavailable, triggering retry for Order #{order_id}"
    end
  end
end
