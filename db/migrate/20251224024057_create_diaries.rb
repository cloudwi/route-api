class CreateDiaries < ActiveRecord::Migration[8.1]
  def change
    create_table :diaries do |t|
      t.string :title, null: false
      t.text :content
      t.references :user, null: false, foreign_key: true, comment: "일기 작성자"

      t.timestamps
    end

    add_index :diaries, :created_at
  end
end
