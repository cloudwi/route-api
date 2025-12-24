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

ActiveRecord::Schema[8.1].define(version: 2025_12_24_090356) do
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

  create_table "couple_invitations", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false, comment: "초대 만료 시간"
    t.bigint "inviter_id", null: false, comment: "초대를 보낸 사용자"
    t.string "token", null: false, comment: "초대 링크 토큰"
    t.datetime "updated_at", null: false
    t.boolean "used", default: false, null: false, comment: "초대 사용 여부"
    t.index ["expires_at"], name: "index_couple_invitations_on_expires_at"
    t.index ["inviter_id"], name: "index_couple_invitations_on_inviter_id"
    t.index ["token"], name: "index_couple_invitations_on_token", unique: true
  end

  create_table "couples", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user1_id", null: false, comment: "커플의 첫 번째 사용자"
    t.bigint "user2_id", null: false, comment: "커플의 두 번째 사용자"
    t.index ["user1_id", "user2_id"], name: "index_couples_on_user1_id_and_user2_id", unique: true
    t.index ["user1_id"], name: "index_couples_on_user1_id"
    t.index ["user2_id"], name: "index_couples_on_user2_id"
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
  add_foreign_key "couple_invitations", "users", column: "inviter_id"
  add_foreign_key "couples", "users", column: "user1_id"
  add_foreign_key "couples", "users", column: "user2_id"
  add_foreign_key "diaries", "users"
end
