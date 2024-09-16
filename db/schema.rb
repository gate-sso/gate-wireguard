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

ActiveRecord::Schema[7.2].define(version: 2024_06_05_090543) do
  create_table "dns_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "host_name"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
  end

  create_table "ip_allocations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "vpn_device_id", null: false
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vpn_device_id"], name: "index_ip_allocations_on_vpn_device_id"
  end

  create_table "network_addresses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "vpn_configuration_id", null: false
    t.string "network_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vpn_configuration_id"], name: "index_network_addresses_on_vpn_configuration_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "email"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin"
  end

  create_table "vpn_configurations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "wg_private_key"
    t.string "wg_public_key"
    t.string "wg_ip_address"
    t.string "wg_port"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "dns_servers"
    t.string "wg_ip_range"
    t.string "wg_interface_name"
    t.string "wg_keep_alive"
    t.string "wg_listen_address"
    t.string "server_vpn_ip_address"
    t.string "wg_forward_interface"
  end

  create_table "vpn_devices", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "description"
    t.string "private_key"
    t.string "public_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "node"
    t.index ["user_id"], name: "index_vpn_devices_on_user_id"
  end

  add_foreign_key "ip_allocations", "vpn_devices"
  add_foreign_key "network_addresses", "vpn_configurations"
  add_foreign_key "vpn_devices", "users"
end
