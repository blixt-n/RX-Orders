class CreatePrescriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :prescriptions do |t|
      t.references :patient, null: false, foreign_key: { to_table: :users }
      t.integer :status, default: 0, null: false
      t.integer :price_cents
      t.string :medication_name

      t.timestamps
    end
  end
end
