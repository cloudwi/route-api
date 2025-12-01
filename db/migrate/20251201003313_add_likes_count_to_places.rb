class AddLikesCountToPlaces < ActiveRecord::Migration[8.1]
  def change
    add_column :places, :likes_count, :integer, default: 0, null: false
  end
end
