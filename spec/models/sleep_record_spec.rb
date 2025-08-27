require 'rails_helper'

RSpec.describe SleepRecord, type: :model do
  describe 'validations' do
    subject { build(:sleep_record) }

    it { should validate_presence_of(:bed_time) }
    it { should validate_numericality_of(:duration_in_seconds).only_integer.is_greater_than_or_equal_to(0).allow_nil }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:completed_record) { create(:sleep_record, :completed, user: user) }
    let!(:ongoing_record) { create(:sleep_record, :ongoing, user: user) }

    describe '.completed' do
      it 'returns only completed sleep records' do
        expect(SleepRecord.completed).to include(completed_record)
        expect(SleepRecord.completed).not_to include(ongoing_record)
      end
    end

    describe '.ongoing' do
      it 'returns only ongoing sleep records' do
        expect(SleepRecord.ongoing).to include(ongoing_record)
        expect(SleepRecord.ongoing).not_to include(completed_record)
      end
    end

    describe '.by_duration' do
      let!(:long_record) { create(:sleep_record, :long_sleep, user: user) }
      let!(:short_record) { create(:sleep_record, :short_sleep, user: user) }

      it 'returns completed records ordered by duration desc' do
        expect(SleepRecord.by_duration.first).to eq(long_record)
        expect(SleepRecord.by_duration.last).to eq(short_record)
      end
    end

    describe '.recent' do
      it 'returns records ordered by created_at desc' do
        expect(SleepRecord.recent.first).to eq(ongoing_record)
        expect(SleepRecord.recent.last).to eq(completed_record)
      end
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
#  user_id             :bigint           not null
#  bed_time            :datetime         not null
#  wake_up_time        :datetime
#  duration_in_seconds :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
