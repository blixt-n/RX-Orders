class Order < ApplicationRecord
  monetize :total_cents

  enum :status, {
    pending: 0,
    processing: 1,
    paid: 2,
    failed: 3
  }

  belongs_to :buyer, class_name: "User"
  belongs_to :prescription
end
