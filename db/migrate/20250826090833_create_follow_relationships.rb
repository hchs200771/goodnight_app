class CreateFollowRelationships < ActiveRecord::Migration[7.2]
  def change
    create_table :follow_relationships do |t|
      # follower: 追蹤者 (主動追蹤別人的人)
      # 例如：Alice 追蹤 Bob，則 Alice 是 follower
      t.references :follower, null: false, foreign_key: { to_table: :users }, comment: "追蹤者ID (主動追蹤別人的人)"

      # followed: 被追蹤者 (被別人追蹤的人)
      # 例如：Alice 追蹤 Bob，則 Bob 是 followed
      t.references :followed, null: false, foreign_key: { to_table: :users }, comment: "被追蹤者ID (被別人追蹤的人)"

      t.timestamps
    end

    # 防止重複追蹤：同一個人不能追蹤同一個人兩次
    add_index :follow_relationships, [:follower_id, :followed_id], unique: true, name: 'index_follow_relationships_on_follower_and_followed'
  end
end
