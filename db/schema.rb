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

ActiveRecord::Schema[8.1].define(version: 2025_12_24_030437) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "diaries", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false, comment: "일기 작성자"
    t.index ["created_at"], name: "index_diaries_on_created_at"
    t.index ["user_id"], name: "index_diaries_on_user_id"
  end

  create_table "diary_users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "diary_id", null: false
    t.string "role", default: "viewer", null: false, comment: "owner, editor, viewer"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["diary_id"], name: "index_diary_users_on_diary_id"
    t.index ["user_id", "diary_id"], name: "index_diary_users_on_user_id_and_diary_id", unique: true
    t.index ["user_id"], name: "index_diary_users_on_user_id"
  end

  create_table "images", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "purpose", comment: "이미지 용도 (place_thumbnail, profile, etc.)"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["created_at"], name: "index_images_on_created_at"
    t.index ["user_id"], name: "index_images_on_user_id"
  end

  create_table "places", id: { comment: "장소 고유 식별자" }, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "address", comment: "지번 주소"
    t.string "category", comment: "장소 카테고리 (예: 카페, 음식점)"
    t.datetime "created_at", null: false, comment: "생성 일시"
    t.decimal "latitude", precision: 10, scale: 7, comment: "위도"
    t.decimal "longitude", precision: 10, scale: 7, comment: "경도"
    t.string "name", comment: "장소 이름"
    t.string "naver_map_url", comment: "네이버 지도 URL"
    t.string "naver_place_id", comment: "네이버 장소 고유 ID"
    t.string "road_address", comment: "도로명 주소"
    t.string "telephone", comment: "전화번호"
    t.datetime "updated_at", null: false, comment: "수정 일시"
    t.bigint "user_id", null: false, comment: "소유자 사용자 ID"
    t.integer "views_count", default: 0, null: false, comment: "조회수"
    t.index ["category"], name: "index_places_on_category"
    t.index ["name"], name: "index_places_on_name"
    t.index ["user_id", "naver_place_id"], name: "index_places_on_user_id_and_naver_place_id", unique: true
    t.index ["user_id"], name: "index_places_on_user_id"
    t.index ["views_count"], name: "index_places_on_views_count"
  end

  create_table "users", id: { comment: "사용자 고유 식별자" }, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false, comment: "생성 일시"
    t.string "email", comment: "사용자 이메일 주소"
    t.string "name", comment: "사용자 이름"
    t.string "profile_image", comment: "프로필 이미지 URL"
    t.string "provider", comment: "OAuth 제공자 (예: kakao)"
    t.string "uid", comment: "OAuth 제공자에서 발급한 고유 ID"
    t.datetime "updated_at", null: false, comment: "수정 일시"
    t.index ["email"], name: "index_users_on_email"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "diaries", "users"
  add_foreign_key "diary_users", "diaries"
  add_foreign_key "diary_users", "users"
  add_foreign_key "images", "users"
  add_foreign_key "places", "users"
end
