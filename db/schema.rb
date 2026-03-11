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

ActiveRecord::Schema[7.2].define(version: 2026_03_07_000002) do
  create_table "short_urls", force: :cascade do |t|
    t.string "path", null: false
    t.string "target_url", null: false
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["path"], name: "index_short_urls_on_path", unique: true
  end

  create_table "visits", force: :cascade do |t|
    t.integer "short_url_id", null: false
    t.string "ip_address"
    t.float "latitude"
    t.float "longitude"
    t.string "country"
    t.datetime "visited_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["short_url_id"], name: "index_visits_on_short_url_id"
    t.index ["visited_at"], name: "index_visits_on_visited_at"
  end

  add_foreign_key "visits", "short_urls"
end
