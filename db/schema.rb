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

ActiveRecord::Schema[8.1].define(version: 2025_12_01_015653) do
  create_table "course_places", id: { comment: "코스-장소 연결 고유 식별자" }, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "course_id", null: false, comment: "코스 ID"
    t.datetime "created_at", null: false, comment: "생성 일시"
    t.bigint "place_id", comment: "장소 ID"
    t.integer "position", comment: "코스 내 장소 순서 (0부터 시작)"
    t.datetime "updated_at", null: false, comment: "수정 일시"
    t.index ["course_id"], name: "index_course_places_on_course_id"
    t.index ["place_id"], name: "index_course_places_on_place_id"
  end

  create_table "courses", id: { comment: "코스 고유 식별자" }, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false, comment: "생성 일시"
    t.string "name", comment: "코스 이름"
    t.datetime "updated_at", null: false, comment: "수정 일시"
    t.bigint "user_id", null: false, comment: "소유자 사용자 ID"
    t.index ["user_id"], name: "index_courses_on_user_id"
  end

  create_table "folders", id: { comment: "폴더 고유 식별자" }, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false, comment: "생성 일시"
    t.text "description", comment: "폴더 설명"
    t.string "name", null: false, comment: "폴더 이름"
    t.bigint "parent_id", comment: "상위 폴더 ID (null이면 루트 폴더)"
    t.datetime "updated_at", null: false, comment: "수정 일시"
    t.bigint "user_id", null: false, comment: "소유자 사용자 ID"
    t.index ["name"], name: "index_folders_on_name"
    t.index ["parent_id"], name: "index_folders_on_parent_id"
    t.index ["user_id", "parent_id"], name: "index_folders_on_user_id_and_parent_id"
    t.index ["user_id"], name: "index_folders_on_user_id"
  end

  create_table "place_likes", id: { comment: "좋아요 고유 식별자" }, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false, comment: "생성 일시"
    t.bigint "place_id", null: false, comment: "좋아요 대상 장소 ID"
    t.datetime "updated_at", null: false, comment: "수정 일시"
    t.bigint "user_id", null: false, comment: "좋아요 누른 사용자 ID"
    t.index ["place_id"], name: "index_place_likes_on_place_id"
    t.index ["user_id", "place_id"], name: "index_place_likes_on_user_id_and_place_id", unique: true
    t.index ["user_id"], name: "index_place_likes_on_user_id"
  end

  create_table "places", id: { comment: "장소 고유 식별자" }, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "address", comment: "지번 주소"
    t.string "category", comment: "장소 카테고리 (예: 카페, 음식점)"
    t.datetime "created_at", null: false, comment: "생성 일시"
    t.decimal "latitude", precision: 10, scale: 7, comment: "위도"
    t.integer "likes_count", default: 0, null: false, comment: "좋아요 수"
    t.decimal "longitude", precision: 10, scale: 7, comment: "경도"
    t.string "name", comment: "장소 이름"
    t.string "naver_map_url", comment: "네이버 지도 URL"
    t.string "naver_place_id", comment: "네이버 장소 고유 ID"
    t.string "road_address", comment: "도로명 주소"
    t.string "telephone", comment: "전화번호"
    t.datetime "updated_at", null: false, comment: "수정 일시"
    t.bigint "user_id", null: false, comment: "소유자 사용자 ID"
    t.integer "views_count", default: 0, null: false, comment: "조회수"
    t.index ["user_id", "naver_place_id"], name: "index_places_on_user_id_and_naver_place_id", unique: true
    t.index ["user_id"], name: "index_places_on_user_id"
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

  add_foreign_key "course_places", "courses"
  add_foreign_key "course_places", "places"
  add_foreign_key "courses", "users"
  add_foreign_key "folders", "folders", column: "parent_id"
  add_foreign_key "folders", "users"
  add_foreign_key "place_likes", "places"
  add_foreign_key "place_likes", "users"
  add_foreign_key "places", "users"
end
