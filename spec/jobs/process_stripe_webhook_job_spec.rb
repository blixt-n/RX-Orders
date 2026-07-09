require "rails_helper"

RSpec.describe ProcessStripeWebhookJob, type: :job do
  let(:order) { create(:order, status: :processing) }
  let(:job) { described_class.new }

  before do
    allow(job).to receive(:log_event)
  end

  describe "#perform" do
    context "when the payload is missing an order_id (Dashboard Event)" do
      it "logs the ignored event and exits cleanly" do
        object_json = { id: "pi_123", metadata: {} }.to_json

        job.perform(event_type: "payment_intent.succeeded", object_json: object_json)

        expect(job).to have_received(:log_event).with(
          "stripe_webhook_ignored",
          level: :info,
          payload: { event_type: "payment_intent.succeeded" }
        )
        expect(order.reload).to be_processing
      end
    end

    context "when the database cannot find the order (Race Condition / DB Lag)" do
      it "raises an ActiveRecord::RecordNotFound error to trigger the queue retry loop" do
        object_json = { id: "pi_123", metadata: { order_id: 999999 } }.to_json

        expect {
          job.perform(event_type: "payment_intent.succeeded", object_json: object_json)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when processing a payment_intent.succeeded event" do
      let(:object_json) { { id: "pi_123", metadata: { order_id: order.id } }.to_json }

      it "updates a processing order to paid" do
        job.perform(event_type: "payment_intent.succeeded", object_json: object_json)
        expect(order.reload).to be_paid
      end

      it "gracefully ignores the event if the order is already paid (idempotency)" do
        order.update!(status: :paid)

        expect {
          job.perform(event_type: "payment_intent.succeeded", object_json: object_json)
        }.not_to raise_error

        expect(order.reload).to be_paid
      end
    end

    context "when processing a payment_intent.payment_failed event" do
      let(:object_json) { { id: "pi_123", metadata: { order_id: order.id } }.to_json }

      it "updates a processing order to failed" do
        job.perform(event_type: "payment_intent.payment_failed", object_json: object_json)
        expect(order.reload).to be_failed
      end

      it "gracefully ignores the event if the order is already failed (idempotency)" do
        order.update!(status: :failed)

        expect {
          job.perform(event_type: "payment_intent.payment_failed", object_json: object_json)
        }.not_to raise_error

        expect(order.reload).to be_failed
      end
    end

    context "when processing an unhandled event type" do
      let(:object_json) { { id: "pi_123", metadata: { order_id: order.id } }.to_json }

      it "logs the unhandled event and leaves the order status alone" do
        job.perform(event_type: "charge.dispute.created", object_json: object_json)

        expect(order.reload).to be_processing
        expect(job).to have_received(:log_event).with(
          "unhandled_stripe_event_type",
          payload: hash_including(event_type: "charge.dispute.created", order_id: order.id)
        )
      end
    end
  end
end
