class FriendsSleepFeedQuery
  attr_reader :follower_id, :start_date, :end_date

  def initialize(follower_id:, start_date: nil, end_date: nil)
    @follower_id = follower_id
    @start_date = start_date || 1.week.ago.beginning_of_week
    @end_date = end_date || 1.week.ago.end_of_week
  end

  def call
    SleepRecord
      .completed
      .joins(:user)
      .joins("INNER JOIN follow_relationships ON users.id = follow_relationships.followed_id")
      .where(follow_relationships: { follower_id: follower_id })
      .where("sleep_records.created_at >= ?", start_date)
      .where("sleep_records.created_at <= ?", end_date)
      .by_duration
      .includes(:user)
  end

  # 可以加入更多查詢方法
  def count
    call.count
  end

  def exists?
    call.exists?
  end
end
