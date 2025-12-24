class CreateDiaryPrompts < ActiveRecord::Migration[8.1]
  def change
    create_table :diary_prompts do |t|
      t.text :content, null: false, comment: "일기 질문 내용"
      t.string :category, comment: "질문 카테고리 (감정, 일상, 관계, 미래 등)"

      t.timestamps
    end

    add_index :diary_prompts, :category
  end
end
