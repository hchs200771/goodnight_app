class RemoveUselessIndexes < ActiveRecord::Migration[7.2]
  def change
    # 移除 sleep_records 的多餘索引
    remove_index :sleep_records, :user_id
    remove_index :sleep_records, :created_at

    # 移除 follow_relationships 的多餘索引
    remove_index :follow_relationships, :follower_id
    remove_index :follow_relationships, :followed_id
  end
end
