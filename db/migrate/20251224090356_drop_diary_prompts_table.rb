class DropDiaryPromptsTable < ActiveRecord::Migration[8.1]
  def change
    drop_table :diary_prompts do |t|
      t.string :category, comment: "질문 카테고리 (감정, 일상, 관계, 미래 등)"
      t.text :content, null: false, comment: "일기 질문 내용"
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index :category, name: "index_diary_prompts_on_category"
    end
  end
end
