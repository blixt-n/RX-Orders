require "rails_helper"
require 'aasm/rspec'

RSpec.describe Order, type: :model do
  describe "state machine" do
    it "defaults to pending" do
      expect(Order.new).to have_state(:pending)
    end

    context "transitions" do
      let(:order) { build(:order) }

      it "transitions from pending to processing on process" do
        expect(order).to transition_from(:pending).to(:processing).on_event(:process)
      end

      it "transitions from processing to failed on fail" do
        order.status = :processing
        expect(order).to transition_from(:processing).to(:failed).on_event(:fail)
      end

      it "updates the status and sets paid_at when calling pay!" do
        order.status = :processing
        order.save
        expect { order.pay! }
          .to change { order.reload.status }.from("processing").to("paid")
                                     .and change { order.reload.paid_at }.from(nil)
      end
    end
  end
end
