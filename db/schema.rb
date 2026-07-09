# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_09_115517) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "orders", force: :cascade do |t|
    t.bigint "buyer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "paid_at"
    t.bigint "prescription_id", null: false
    t.integer "status", default: 0, null: false
    t.string "stripe_payment_intent_id"
    t.integer "total_cents"
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_orders_on_buyer_id"
    t.index ["prescription_id"], name: "index_orders_on_prescription_id"
  end

  create_table "prescriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "medication_name"
    t.bigint "patient_id", null: false
    t.integer "price_cents"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_prescriptions_on_patient_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "phone_number"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
  end

  add_foreign_key "orders", "prescriptions"
  add_foreign_key "orders", "users", column: "buyer_id"
  add_foreign_key "prescriptions", "users", column: "patient_id"
end
