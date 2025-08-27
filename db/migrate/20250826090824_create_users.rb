class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      # 使用者的姓名，用於顯示和識別
      # 限制長度：最少1字元，最多100字元
      t.string :name, null: false, limit: 100, comment: "使用者姓名"

      t.timestamps
    end
  end
end
