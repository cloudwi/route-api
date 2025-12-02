class DropFolders < ActiveRecord::Migration[8.1]
  def change
    drop_table :folders, if_exists: true
  end
end
