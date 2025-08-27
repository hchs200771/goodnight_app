class User < ApplicationRecord
  # Validations
  validates :name, presence: true, length: { minimum: 1, maximum: 100 }

  # Associations
  has_many :sleep_records, dependent: :destroy

  # Following relationships
  has_many :following_relationships, class_name: "FollowRelationship", foreign_key: "follower_id", dependent: :destroy
  has_many :following, through: :following_relationships, source: :followed

  has_many :follower_relationships, class_name: "FollowRelationship", foreign_key: "followed_id", dependent: :destroy
  has_many :followers, through: :follower_relationships, source: :follower

  # Instance methods
  def follow(user)
    return false if self == user

    following_relationships.create(followed: user) unless following?(user)
  end

  def unfollow(user)
    following_relationships.find_by(followed: user)&.destroy
  end

  def following?(user)
    # 使用 exists? 避免載入整個關聯
    following_relationships.exists?(followed: user)
  end

  def current_sleep_record
    sleep_records.ongoing.last
  end
end

# == Schema Information
#
# Table name: users
#
#  id         :bigint           not null, primary key
#  name       :string(100)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
