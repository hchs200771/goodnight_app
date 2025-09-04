FactoryBot.define do
  factory :sleep_record do
    association :user

    trait :completed do
      wake_up_time { Time.current }
      created_at { 8.hours.ago }
    end

    trait :ongoing do
      wake_up_time { nil }
      created_at { 8.hours.ago }
    end

    trait :long_sleep do
      wake_up_time { 2.hours.ago }
    end

    trait :short_sleep do
      wake_up_time { 1.hour.ago }
    end

    trait :overnight do
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
