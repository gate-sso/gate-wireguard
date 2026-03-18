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

ActiveRecord::Schema[8.1].define(version: 2026_03_18_000002) do
  create_table "api_keys", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_used_at"
    t.string "name", limit: 100, null: false
    t.datetime "revoked_at"
    t.string "token_digest", limit: 64, null: false
    t.datetime "updated_at", null: false
    t.index ["revoked_at"], name: "index_api_keys_on_revoked_at"
    t.index ["token_digest"], name: "index_api_keys_on_token_digest", unique: true
  end

  create_table "dns_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "host_name"
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
  end

  create_table "ip_allocations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "allocated", default: true, null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.bigint "vpn_device_id"
    t.index ["allocated"], name: "index_ip_allocations_on_allocated"
    t.index ["vpn_device_id"], name: "index_ip_allocations_on_vpn_device_id"
  end

  create_table "network_addresses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "network_address"
    t.datetime "updated_at", null: false
    t.bigint "vpn_configuration_id", null: false
    t.index ["vpn_configuration_id"], name: "index_network_addresses_on_vpn_configuration_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.text "profile_picture_url"
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", null: false
  end

  create_table "vpn_configurations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "dns_servers"
    t.string "server_vpn_ip_address"
    t.datetime "updated_at", null: false
    t.string "wg_forward_interface"
    t.string "wg_fqdn"
    t.string "wg_interface_name"
    t.string "wg_ip_address"
    t.string "wg_ip_range"
    t.string "wg_keep_alive"
    t.string "wg_listen_address"
    t.string "wg_port"
    t.string "wg_private_key"
    t.string "wg_public_key"
  end

  create_table "vpn_devices", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "node"
    t.string "private_key"
    t.string "public_key"
    t.text "served_networks"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_vpn_devices_on_user_id"
  end

  add_foreign_key "network_addresses", "vpn_configurations"
  add_foreign_key "vpn_devices", "users"
end
