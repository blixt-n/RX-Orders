class Prescription < ApplicationRecord
  monetize :price_cents

  enum :status, {
    pending_verification: 0,
    active: 1,
    exhausted: 2,
    expired: 3,
    cancelled: 4
  }

  belongs_to :patient, class_name: "User"
  has_many :orders
end
