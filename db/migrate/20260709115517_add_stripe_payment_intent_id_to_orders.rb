class AddStripePaymentIntentIdToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :stripe_payment_intent_id, :string
  end
end
