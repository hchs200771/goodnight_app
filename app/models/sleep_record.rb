class SleepRecord < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :bed_time, presence: true
  validates :duration_in_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # Callbacks
  before_validation :calculate_duration, if: :wake_up_time_changed?

  # Scopes
  scope :completed, -> { where.not(duration_in_seconds: nil) }
  scope :ongoing, -> { where(duration_in_seconds: nil) }
  scope :by_duration, -> { completed.order(duration_in_seconds: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  # Class Methods
  # 朋友睡眠紀錄查詢 - 使用分步驟查詢優化效能
  def self.friends_sleep_feed(follower_id:, start_date: nil, end_date: nil, page: nil, per_page: nil)
    # 設定預設時間範圍
    start_date ||= 1.week.ago.beginning_of_week
    end_date ||= 1.week.ago.end_of_week

    # 參數驗證
    validate_friends_sleep_feed_params(follower_id, start_date, end_date)

    # 步驟 1: 先篩選出要追蹤的使用者 ID
    followed_user_ids = FollowRelationship
      .where(follower_id: follower_id)
      .pluck(:followed_id)

    return [] if followed_user_ids.empty?

    # 步驟 2: 再查詢這些使用者的睡眠紀錄
    query = completed
      .where(user_id: followed_user_ids)
      .where(created_at: start_date..end_date)
      .includes(:user)
      .by_duration

    # 步驟 3: 加入分頁（如果提供分頁參數）
    if page && per_page
      query = query.offset((page - 1) * per_page).limit(per_page)
    end

    query
  end

  # 私有方法：參數驗證
  def self.validate_friends_sleep_feed_params(follower_id, start_date, end_date)
    raise ArgumentError, 'follower_id is required' if follower_id.blank?
    raise ArgumentError, 'start_date must be a Date/Time' unless start_date.is_a?(Date) || start_date.is_a?(Time)
    raise ArgumentError, 'end_date must be a Date/Time' unless end_date.is_a?(Date) || end_date.is_a?(Time)
    raise ArgumentError, 'start_date must be before end_date' if start_date >= end_date
  end

  private_class_method :validate_friends_sleep_feed_params

  # Instance methods
  def duration_in_hours
    return nil unless duration_in_seconds
    (duration_in_seconds / 3600.0).round(2)
  end

  def ongoing?
    wake_up_time.nil?
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
