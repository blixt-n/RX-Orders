class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.references :prescription, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.integer :total_cents
      t.datetime :paid_at

      t.timestamps
    end
  end
end
