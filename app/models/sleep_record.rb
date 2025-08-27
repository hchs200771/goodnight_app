class SleepRecord < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :bed_time, presence: true
  validates :duration_in_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # Callbacks
  before_validation :calculate_duration, if: :wake_up_time_changed?

  # Scopes
  scope :completed, -> { where.not(wake_up_time: nil) }
  scope :ongoing, -> { where(wake_up_time: nil) }
  scope :by_duration, -> { completed.order(duration_in_seconds: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def duration_in_hours
    return nil unless duration_in_seconds
    (duration_in_seconds / 3600.0).round(2)
  end

  def duration_in_minutes
    return nil unless duration_in_seconds
    (duration_in_seconds / 60.0).round(2)
  end

  private

  def calculate_duration
    return unless wake_up_time

    if wake_up_time > bed_time
      self.duration_in_seconds = (wake_up_time - bed_time).to_i
    else
      # wake_up_time <= bed_time 表示時間設定錯誤
      errors.add(:wake_up_time, "起床時間必須晚於上床時間")
      return false
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
