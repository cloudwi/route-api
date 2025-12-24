class DropDiaryUsersTable < ActiveRecord::Migration[8.1]
  def up
    drop_table :diary_users, if_exists: true
  end

  def down
    # diary_users 테이블 복구는 지원하지 않음
    raise ActiveRecord::IrreversibleMigration
  end
end
