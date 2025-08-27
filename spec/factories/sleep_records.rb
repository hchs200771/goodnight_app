FactoryBot.define do
  factory :sleep_record do
    association :user
    bed_time { 8.hours.ago }

    trait :completed do
      wake_up_time { Time.current }
    end

    trait :ongoing do
      wake_up_time { nil }
    end

    trait :long_sleep do
      bed_time { 10.hours.ago }
      wake_up_time { 2.hours.ago }
    end

    trait :short_sleep do
      bed_time { 6.hours.ago }
      wake_up_time { 1.hour.ago }
    end

    trait :overnight do
      bed_time { 1.day.ago + 22.hours } # 10 PM yesterday
      wake_up_time { 1.day.ago + 30.hours } # 6 AM today (30 hours = 24 + 6)
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
