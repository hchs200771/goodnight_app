FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }

    trait :with_sleep_records do
      after(:create) do |user|
        create_list(:sleep_record, 3, user: user)
      end
    end

    trait :with_followers do
      after(:create) do |user|
        followers = create_list(:user, 2)
        followers.each { |follower| follower.follow(user) }
      end
    end

    trait :with_following do
      after(:create) do |user|
        following = create_list(:user, 2)
        following.each { |followed| user.follow(followed) }
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
