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

ActiveRecord::Schema[8.1].define(version: 2025_12_01_003313) do
  create_table "course_places", force: :cascade do |t|
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.integer "place_id"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_places_on_course_id"
    t.index ["place_id"], name: "index_course_places_on_place_id"
  end

  create_table "courses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_courses_on_user_id"
  end

  create_table "folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "parent_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["name"], name: "index_folders_on_name"
    t.index ["parent_id"], name: "index_folders_on_parent_id"
    t.index ["user_id", "parent_id"], name: "index_folders_on_user_id_and_parent_id"
    t.index ["user_id"], name: "index_folders_on_user_id"
  end

  create_table "place_likes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "place_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["place_id"], name: "index_place_likes_on_place_id"
    t.index ["user_id"], name: "index_place_likes_on_user_id"
  end

  create_table "places", force: :cascade do |t|
    t.string "address"
    t.string "category"
    t.datetime "created_at", null: false
    t.decimal "latitude", precision: 10, scale: 7
    t.integer "likes_count", default: 0, null: false
    t.decimal "longitude", precision: 10, scale: 7
    t.string "name"
    t.string "naver_map_url"
    t.string "naver_place_id"
    t.string "road_address"
    t.string "telephone"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "views_count", default: 0, null: false
    t.index ["user_id", "naver_place_id"], name: "index_places_on_user_id_and_naver_place_id", unique: true
    t.index ["user_id"], name: "index_places_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "profile_image"
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  add_foreign_key "course_places", "courses"
  add_foreign_key "course_places", "places"
  add_foreign_key "courses", "users"
  add_foreign_key "folders", "folders", column: "parent_id"
  add_foreign_key "folders", "users"
  add_foreign_key "place_likes", "places"
  add_foreign_key "place_likes", "users"
  add_foreign_key "places", "users"
end
