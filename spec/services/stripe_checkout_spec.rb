require "rails_helper"

RSpec.describe StripeCheckout do
  let(:order) { create(:order, total_cents: 5000, status: :pending) }
  let(:service) { described_class.new(order) }
  let(:mock_intent) { instance_double(Stripe::PaymentIntent, id: "pi_123", client_secret: "secret_123") }

  before do
    allow(Rails.error).to receive(:report)
  end

  describe "#call" do
    context "when the Stripe API succeeds and the order updates" do
      before do
        allow(Stripe::PaymentIntent).to receive(:create).and_return(mock_intent)
        @result = service.call
      end

      it "returns a success flag and client secret" do
        expect(@result[:success]).to be(true)
        expect(@result[:client_secret]).to eq("secret_123")
      end

      it "updates the order status to processing" do
        expect(order.reload).to be_processing
      end

      it "saves the stripe payment intent id on the order" do
        expect(order.reload.stripe_payment_intent_id).to eq("pi_123")
      end

      it "calls the Stripe API with the correct parameters, including the 'order_id' in metadata" do
        expect(Stripe::PaymentIntent).to have_received(:create).with(
          hash_including(
            amount: 5000,
            currency: "usd",
            metadata: { order_id: order.id }
          ),
          hash_including(:idempotency_key)
        )
      end
    end

    context "when the order database update fails" do
      before do
        allow(Stripe::PaymentIntent).to receive(:create).and_return(mock_intent)

        allow(order).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(order))
        @result = service.call
      end

      it "returns a failure flag" do
        expect(@result[:success]).to be(false)
      end

      it "returns a generic error message" do
        expect(@result[:error]).to eq(StripeCheckout::GENERIC_SYSTEM_ERROR_MSG)
      end

      it "reports the exception to the error tracker" do
        expect(Rails.error).to have_received(:report).with(
          instance_of(ActiveRecord::RecordInvalid),
          hash_including(severity: :error)
        )
      end
    end

    context "when Stripe raises an API error" do
      before do
        allow(Stripe::PaymentIntent).to receive(:create).and_raise(Stripe::StripeError, "Invalid API Key")
        @result = service.call
      end

      it "returns a failure flag" do
        expect(@result[:success]).to be(false)
      end

      it "returns a generic system error message to hide the raw failure" do
        expect(@result[:error]).to eq(StripeCheckout::GENERIC_SYSTEM_ERROR_MSG)
      end

      it "leaves the order in a pending status" do
        expect(order.reload.status).to eq("pending")
      end

      it "reports the exception to the error tracker" do
        expect(Rails.error).to have_received(:report).with(
          instance_of(Stripe::StripeError),
          hash_including(severity: :error)
        )
      end
    end

    context "when the circuit breaker is open" do
      before do
        allow(STRIPE_CIRCUIT).to receive(:run).and_raise(Circuitbox::OpenCircuitError.new("stripe"))
        @result = service.call
      end

      it "returns a failure flag" do
        expect(@result[:success]).to be(false)
      end

      it "returns a gateway unavailable message" do
        expect(@result[:error]).to eq(StripeCheckout::GATEWAY_UNAVAILABLE_MSG)
      end

      it "leaves the order in a pending status" do
        expect(order.reload.status).to eq("pending")
      end

      it "reports the open circuit exception to the error tracker" do
        expect(Rails.error).to have_received(:report).with(
          instance_of(Circuitbox::OpenCircuitError),
          hash_including(severity: :error)
        )
      end
    end
  end
end
