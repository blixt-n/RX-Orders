class Order < ApplicationRecord
  include AASM

  monetize :total_cents

  enum :status, {
    pending: 0,
    processing: 1,
    paid: 2,
    failed: 3
  }

  belongs_to :buyer, class_name: "User"
  belongs_to :prescription

  aasm column: :status, enum: true do
    state :pending, initial: true
    state :processing
    state :paid
    state :failed

    event :process do
      transitions from: :pending, to: :processing
    end

    event :pay do
      transitions from: :processing, to: :paid, after: :set_paid_at
    end

    event :fail do
      transitions from: :processing, to: :failed
    end
  end

  private

  def set_paid_at
    self.paid_at = Time.current
  end
end
