require "rails_helper"

RSpec.describe "Api::V1::Checkouts", type: :request do
  describe "POST /api/orders/:order_id/checkout" do
    let(:order) { create(:order) }
    let(:valid_headers) { { "ACCEPT" => "application/json" } }
    let(:json_response) { JSON.parse(response.body, symbolize_names: true) }

    context "when the service returns success" do
      before do
        allow_any_instance_of(StripeCheckout).to receive(:call).and_return(
          { success: true, client_secret: "pi_123_secret_456" }
        )
        post api_v1_order_checkout_url(order), headers: valid_headers
      end

      it "returns a 200 OK status" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the correct client secret in the JSON payload" do
        expect(json_response[:client_secret]).to eq("pi_123_secret_456")
      end
    end

    context "when the service returns a failure" do
      before do
        allow_any_instance_of(StripeCheckout).to receive(:call).and_return(
          { success: false, error: "Payment gateway temporarily unavailable" }
        )
        post api_v1_order_checkout_url(order), headers: valid_headers
      end

      it "returns a 422 Unprocessable Entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns the exact error message from the service" do
        expect(json_response[:error]).to eq("Payment gateway temporarily unavailable")
      end
    end

    context "when the order does not exist" do
      before do
        post api_v1_order_checkout_url(order_id: 0), headers: valid_headers
      end

      it "returns a 404 Not Found status" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns an active record missing error message" do
        expect(json_response[:error]).to include("Couldn't find Order")
      end
    end
  end
end
