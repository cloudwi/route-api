class CreateCoupleInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :couple_invitations do |t|
      t.references :inviter, null: false, foreign_key: { to_table: :users }, comment: "초대를 보낸 사용자"
      t.string :token, null: false, comment: "초대 링크 토큰"
      t.datetime :expires_at, null: false, comment: "초대 만료 시간"
      t.boolean :used, default: false, null: false, comment: "초대 사용 여부"

      t.timestamps
    end

    add_index :couple_invitations, :token, unique: true
    add_index :couple_invitations, :expires_at
  end
end
