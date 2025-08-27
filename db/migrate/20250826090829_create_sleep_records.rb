class CreateSleepRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :sleep_records do |t|
      # 關聯到使用者，一個使用者可以有多筆睡眠紀錄
      t.references :user, null: false, foreign_key: true, comment: "使用者ID"

      # 使用者上床睡覺的時間點
      t.datetime :bed_time, null: false, comment: "上床時間"

      # 使用者起床的時間點，NULL 表示還在睡覺中
      t.datetime :wake_up_time, comment: "起床時間"

      # 睡眠時長（秒），在記錄起床時間時自動計算
      t.integer :duration_in_seconds, comment: "睡眠時長（秒）"

      t.timestamps
    end

    # 為建立時間建立索引，支援時間範圍查詢
    add_index :sleep_records, :created_at

    # 為睡眠時長建立索引，支援排序查詢（朋友睡眠牆：按睡眠時長降序）
    add_index :sleep_records, :duration_in_seconds
  end
end
