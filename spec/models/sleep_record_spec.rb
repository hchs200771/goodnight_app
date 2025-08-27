require 'rails_helper'

RSpec.describe SleepRecord, type: :model do
  describe '.friends_sleep_feed' do
    let(:follower) { create(:user) }
    let(:friend1) { create(:user) }
    let(:friend2) { create(:user) }
    let(:non_friend) { create(:user) }

    let!(:follow_relationship1) { create(:follow_relationship, follower: follower, followed: friend1) }
    let!(:follow_relationship2) { create(:follow_relationship, follower: follower, followed: friend2) }

    # 使用默认日期范围（1.week.ago）
    let(:default_start_date) { 1.week.ago.beginning_of_week }
    let(:default_end_date) { 1.week.ago.end_of_week }

    let!(:friend1_record) { create(:sleep_record, :completed, user: friend1, created_at: default_start_date + 1.day) }
    let!(:friend2_record) { create(:sleep_record, :completed, user: friend2, created_at: default_start_date + 2.days) }
    let!(:non_friend_record) { create(:sleep_record, :completed, user: non_friend, created_at: default_start_date + 1.day) }

    it 'returns sleep records from followed users only' do
      result = SleepRecord.friends_sleep_feed(follower_id: follower.id)

      expect(result).to include(friend1_record)
      expect(result).to include(friend2_record)
      expect(result).not_to include(non_friend_record)
    end

    it 'filters records by custom date range' do
      custom_start = 2.weeks.ago.beginning_of_week
      custom_end = 2.weeks.ago.end_of_week

      old_record = create(:sleep_record, :completed, user: friend1, created_at: custom_start + 1.day)

      result = SleepRecord.friends_sleep_feed(
        follower_id: follower.id,
        start_date: custom_start,
        end_date: custom_end
      )

      expect(result).to include(old_record)
      expect(result).not_to include(friend1_record)
    end

    it 'orders records by duration in descending order' do
      # 验证查询结果是否按 duration_in_seconds 降序排列
      result = SleepRecord.friends_sleep_feed(follower_id: follower.id)

      # 检查是否按降序排列（每个元素都应该大于等于下一个元素）
      result_durations = result.pluck(:duration_in_seconds)
      expect(result_durations).to eq(result_durations.sort.reverse)

      # 验证返回的记录都是已完成的（有 duration_in_seconds）
      expect(result.all? { |record| record.duration_in_seconds.present? }).to be true
    end

    it 'returns empty array when user has no friends' do
      user_without_friends = create(:user)

      result = SleepRecord.friends_sleep_feed(follower_id: user_without_friends.id)

      expect(result).to be_empty
    end

    it 'applies pagination when provided' do
      create_list(:sleep_record, 5, :completed, user: friend1, created_at: default_start_date + 1.day)

      result = SleepRecord.friends_sleep_feed(
        follower_id: follower.id,
        page: 1,
        per_page: 3
      )

      expect(result.count).to eq(3)
    end

    it 'uses default date range when not provided' do
      result = SleepRecord.friends_sleep_feed(follower_id: follower.id)

      expect(result).not_to be_empty
      expect(result).to include(friend1_record)
    end

    it 'raises error for invalid follower_id' do
      expect {
        SleepRecord.friends_sleep_feed(follower_id: nil)
      }.to raise_error(ArgumentError, 'follower_id is required')
    end

    it 'raises error for invalid date range' do
      expect {
        SleepRecord.friends_sleep_feed(
          follower_id: follower.id,
          start_date: default_end_date,
          end_date: default_start_date
        )
      }.to raise_error(ArgumentError, 'start_date must be before end_date')
    end
  end

  describe 'callbacks' do
    let(:user) { create(:user) }

    describe 'before_validation :calculate_duration' do
      it 'calculates duration when wake_up_time is set' do
        sleep_record = create(:sleep_record, :ongoing, user: user)
        sleep_record.update!(wake_up_time: Time.current)

        expect(sleep_record.duration_in_seconds).to be_present
        expect(sleep_record.duration_in_seconds).to be > 0
      end

      it 'does not calculate duration when wake_up_time is nil' do
        sleep_record = create(:sleep_record, :ongoing, user: user)
        expect(sleep_record.duration_in_seconds).to be_nil
      end

      it 'handles overnight sleep correctly' do
        sleep_record = create(:sleep_record, :overnight, user: user)
        expect(sleep_record.duration_in_seconds).to be > 0
      end
    end
  end
end

# == Schema Information
#
# Table name: sleep_records
#
#  id                  :bigint           not null, primary key
#  bed_time            :datetime         not null
#  wake_up_time        :datetime
#  duration_in_seconds :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
