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

ActiveRecord::Schema[7.2].define(version: 2025_09_04_035935) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "follow_relationships", force: :cascade do |t|
    t.bigint "follower_id", null: false, comment: "追蹤者ID (主動追蹤別人的人)"
    t.bigint "followed_id", null: false, comment: "被追蹤者ID (被別人追蹤的人)"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["follower_id", "followed_id"], name: "index_follow_relationships_on_follower_and_followed", unique: true
  end

  create_table "sleep_records", force: :cascade do |t|
    t.bigint "user_id", null: false, comment: "使用者ID"
    t.datetime "wake_up_time", comment: "起床時間"
    t.integer "duration_in_seconds", comment: "睡眠時長（秒）"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at", "duration_in_seconds"], name: "index_sleep_records_on_user_created_duration"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", limit: 100, null: false, comment: "使用者姓名"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "follow_relationships", "users", column: "followed_id"
  add_foreign_key "follow_relationships", "users", column: "follower_id"
  add_foreign_key "sleep_records", "users"
end
