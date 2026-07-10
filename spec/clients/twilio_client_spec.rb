require "rails_helper"

RSpec.describe TwilioClient, type: :client do
  let(:client) { described_class.new }
  let(:to_phone) { "555-867-5309" }
  let(:body_text) { "Your order is ready!" }
  let(:twilio_url) { "https://api.twilio.com/2010-04-01/Accounts/#{TWILIO_ACCOUNT_SID}/Messages.json" }

  describe "#send_sms" do
    context "when the request is successful" do
      before do
        stub_request(:post, twilio_url)
          .to_return(status: 201, body: { sid: "SMmock12345" }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "formats the phone number and returns success" do
        result = client.send_sms(phone_number: to_phone, body: body_text)

        expect(result[:success]).to be(true)
        expect(result[:message_sid]).to eq("SMmock12345")

        expect(WebMock).to have_requested(:post, twilio_url)
                             .with(body: hash_including("To" => "+15558675309"))
      end
    end

    context "when Twilio returns a REST error" do
      before do
        stub_request(:post, twilio_url)
          .to_return(status: 400, body: { code: 21211, message: "Invalid number" }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "rescues Twilio::REST::RestError and returns the specific message" do
        result = client.send_sms(phone_number: "bad-number", body: body_text)

        expect(result[:success]).to be(false)
        expect(result[:error]).to include("Invalid number")
      end
    end

    context "when a network connection fails" do
      before do
        stub_request(:post, twilio_url).to_raise(Faraday::ConnectionFailed.new("execution expired"))
      end

      it "rescues Faraday::Error and returns a service unavailable message" do
        result = client.send_sms(phone_number: to_phone, body: body_text)

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq(TwilioClient::SERVICE_UNAVAILABLE_MSG)
      end
    end

    context "when the circuit breaker is open" do
      before do
        allow(TWILIO_CIRCUIT).to receive(:run).and_raise(Circuitbox::OpenCircuitError.new(:twilio_api))
      end

      it "rescues the circuit error and returns a service unavailable message" do
        result = client.send_sms(phone_number: to_phone, body: body_text)

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq(TwilioClient::SERVICE_UNAVAILABLE_MSG)
      end
    end

    context "when an unexpected StandardError occurs" do
      before do
        allow_any_instance_of(String).to receive(:gsub).and_raise(StandardError.new("Regex engine failed"))
      end

      it "rescues the generic error and returns the generic error message" do
        result = client.send_sms(phone_number: to_phone, body: body_text)

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq(TwilioClient::GENERIC_ERROR_MSG)
      end
    end
  end
end