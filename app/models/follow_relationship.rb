class FollowRelationship < ApplicationRecord
  # Associations
  belongs_to :follower, class_name: 'User'
  belongs_to :followed, class_name: 'User'

  # Validations
  validates :follower_id, presence: true
  validates :followed_id, presence: true
  validates :follower_id, uniqueness: { scope: :followed_id, message: 'already follows this user' }
  validate :cannot_follow_self

  private

  def cannot_follow_self
    if follower_id == followed_id
      errors.add(:base, 'Cannot follow yourself')
    end
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
