require 'rails_helper'

RSpec.describe FollowRelationship, type: :model do
  describe 'custom validations' do
    let(:user) { create(:user) }

    describe 'cannot_follow_self' do
      it 'prevents user from following themselves' do
        follow_relationship = FollowRelationship.new(follower: user, followed: user)
        expect(follow_relationship).not_to be_valid
        expect(follow_relationship.errors[:base]).to include('Cannot follow yourself')
      end
    end
  end

  describe 'database constraints' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it 'enforces unique constraint on follower and followed combination' do
      create(:follow_relationship, follower: user1, followed: user2)

      # The second attempt should fail validation, not database constraint
      expect {
        create(:follow_relationship, follower: user1, followed: user2)
      }.to raise_error(ActiveRecord::RecordInvalid, /Follower already follows this user/)
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
