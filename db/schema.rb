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

ActiveRecord::Schema[8.1].define(version: 2026_06_01_183200) do
  create_table "comments", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "specimen_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["specimen_id"], name: "index_comments_on_specimen_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "likes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "specimen_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["specimen_id"], name: "index_likes_on_specimen_id"
    t.index ["user_id", "specimen_id"], name: "index_likes_on_user_id_and_specimen_id", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "specimens", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.text "fact"
    t.decimal "mohs", precision: 4, scale: 1
    t.string "name", null: false
    t.string "origin"
    t.string "tint", default: "slate"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["name"], name: "index_specimens_on_name"
    t.index ["user_id"], name: "index_specimens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "comments", "specimens"
  add_foreign_key "comments", "users"
  add_foreign_key "likes", "specimens"
  add_foreign_key "likes", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "specimens", "users", on_delete: :nullify
end
