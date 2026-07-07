class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :phone_number, presence: true, uniqueness: true

  has_many :prescriptions, foreign_key: "patient_id"
  has_many :orders, foreign_key: "buyer_id"
end
