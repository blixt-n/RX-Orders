require 'rails_helper'

RSpec.describe SendOrderPaidSmsJob, type: :job do
  let(:buyer) { create(:user, phone_number: "555-555-5555") }
  let(:order) { create(:order, buyer: buyer) }
  let(:mock_client) { instance_double(TwilioClient) }

  before do
    allow(TwilioClient).to receive(:new).and_return(mock_client)
  end

  describe "#perform" do
    it "sends an SMS successfully" do
      expect(mock_client).to receive(:send_sms).with(
        phone_number: "555-555-5555",
        body: "Great news! Your order ##{order.id} has been paid and is now being processed."
      ).and_return({ success: true, message_sid: "SM123" })

      SendOrderPaidSmsJob.new.perform(order.id)
    end

    it "exits quietly if the order cannot be found" do
      expect(TwilioClient).not_to receive(:new)
      SendOrderPaidSmsJob.new.perform(99999)
    end

    it "exits quietly if the buyer has no phone number" do
      buyer.update_column(:phone_number, nil)
      expect(TwilioClient).not_to receive(:new)
      SendOrderPaidSmsJob.new.perform(order.id)
    end

    it "does not raise an error for a 400 validation failure (so it doesn't retry)" do
      allow(mock_client).to receive(:send_sms).and_return({ success: false, error: "Invalid number" })

      expect { SendOrderPaidSmsJob.new.perform(order.id) }.not_to raise_error
    end

    it "raises an error for network failures to trigger a Sidekiq retry" do
      allow(mock_client).to receive(:send_sms).and_return({ success: false, error: TwilioClient::SERVICE_UNAVAILABLE_MSG })

      expect { SendOrderPaidSmsJob.new.perform(order.id) }.to raise_error(/Twilio service unavailable/)
    end
  end
end
