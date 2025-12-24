class CreateCouples < ActiveRecord::Migration[8.1]
  def change
    create_table :couples do |t|
      t.references :user1, null: false, foreign_key: { to_table: :users }, comment: "커플의 첫 번째 사용자"
      t.references :user2, null: false, foreign_key: { to_table: :users }, comment: "커플의 두 번째 사용자"

      t.timestamps
    end

    # 중복 방지를 위한 유니크 인덱스 (user1_id < user2_id 보장)
    add_index :couples, [ :user1_id, :user2_id ], unique: true
  end
end
