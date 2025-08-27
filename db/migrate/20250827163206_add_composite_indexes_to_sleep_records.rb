class AddCompositeIndexesToSleepRecords < ActiveRecord::Migration[7.2]
  def change
    # 主要查詢索引：用於 friends_sleep_feed 的 WHERE 條件和排序
    add_index :sleep_records, [ :user_id, :created_at, :duration_in_seconds ],
              name: 'index_sleep_records_on_user_created_duration'
  end
end
