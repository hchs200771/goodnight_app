FactoryBot.define do
  factory :follow_relationship do
    follower { create(:user) }
    followed { create(:user) }
  end
end

# == Schema Information
#
# Table name: follow_relationships
#
#  id          :bigint           not null, primary key
#  follower_id :bigint           not null
#  followed_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
