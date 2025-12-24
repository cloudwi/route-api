class CreateDiaryUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :diary_users do |t|
      t.references :user, null: false, foreign_key: true
      t.references :diary, null: false, foreign_key: true
      t.string :role, default: "viewer", null: false, comment: "owner, editor, viewer"

      t.timestamps
    end

    add_index :diary_users, [ :user_id, :diary_id ], unique: true
  end
end
