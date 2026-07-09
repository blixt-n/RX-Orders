require "rails_helper"

RSpec.describe "Api::V1::Webhooks::Stripe", type: :request do
  before do
    allow(Rails.error).to receive(:report)
  end

  describe "POST /api/v1/webhooks/stripe" do
    let(:headers) { { "HTTP_STRIPE_SIGNATURE" => "fake_valid_signature" } }
    let(:payload) { { id: "evt_123" }.to_json }

    context "when the payload and signature are valid" do
      before do
        mock_event = instance_double(Stripe::Event, type: "payment_intent.succeeded")
        mock_data = double("data", object: double("object", to_json: '{"id":"pi_123"}'))
        allow(mock_event).to receive(:data).and_return(mock_data)

        allow(Stripe::Webhook).to receive(:construct_event).and_return(mock_event)

        post api_v1_webhooks_stripe_url, params: payload, headers: headers
      end

      it "returns a 200 OK status" do
        expect(response).to have_http_status(:ok)
      end

      it "enqueues the background job" do
        expect(ProcessStripeWebhookJob).to have_been_enqueued.with(
          event_type: "payment_intent.succeeded",
          object_json: '{"id":"pi_123"}'
        )
      end
    end

    context "when the payload is invalid JSON" do
      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(JSON::ParserError, "unexpected token")

        post api_v1_webhooks_stripe_url, params: "invalid string", headers: headers
      end

      it "returns a 400 Bad Request status" do
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when the signature verification fails" do
      before do
        allow(Stripe::Webhook).to receive(:construct_event)
                                    .and_raise(Stripe::SignatureVerificationError.new("invalid", "sig"))

        post api_v1_webhooks_stripe_url, params: payload, headers: { "HTTP_STRIPE_SIGNATURE" => "invalid_sig" }
      end

      it "returns a 400 Bad Request status" do
        expect(response).to have_http_status(:bad_request)
      end

      it "reports the security warning to the error tracker" do
        expect(Rails.error).to have_received(:report).with(
          instance_of(Stripe::SignatureVerificationError),
          hash_including(
            severity: :error,
            context: hash_including(custom_message: Api::V1::Webhooks::StripeController::SIGNATURE_ERROR_MSG)
          )
        )
      end
    end
  end
end
