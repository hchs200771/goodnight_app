require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    describe '#follow' do
      it 'follows another user' do
        expect { user.follow(other_user) }.to change { user.following?(other_user) }.from(false).to(true)
      end

      it 'does not follow the same user twice' do
        user.follow(other_user)
        expect { user.follow(other_user) }.not_to change { user.following?(other_user) }
      end

      it 'cannot follow self' do
        expect(user.follow(user)).to be false
        expect(user.following?(user)).to be false
      end
    end

    describe '#unfollow' do
      before { user.follow(other_user) }

      it 'unfollows a user' do
        expect { user.unfollow(other_user) }.to change { user.following?(other_user) }.from(true).to(false)
      end
    end

    describe '#following?' do
      it 'returns true when following a user' do
        user.follow(other_user)
        expect(user.following?(other_user)).to be true
      end

      it 'returns false when not following a user' do
        expect(user.following?(other_user)).to be false
      end
    end

    describe '#sleep_records_with_duration' do
      let!(:completed_record) { create(:sleep_record, :completed, user: user) }
      let!(:ongoing_record) { create(:sleep_record, :ongoing, user: user) }

      it 'returns only completed sleep records' do
        expect(user.sleep_records_with_duration).to include(completed_record)
        expect(user.sleep_records_with_duration).not_to include(ongoing_record)
      end

      it 'orders by created_at desc' do
        expect(user.sleep_records_with_duration.first).to eq(completed_record)
      end
    end

    describe '#current_sleep_record' do
      let!(:completed_record) { create(:sleep_record, :completed, user: user) }
      let!(:ongoing_record) { create(:sleep_record, :ongoing, user: user) }

      it 'returns the ongoing sleep record' do
        expect(user.current_sleep_record).to eq(ongoing_record)
      end
    end
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
