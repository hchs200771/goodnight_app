module Api
  module V1
    class SleepRecordsController < ApplicationController
      include ReadReplica

      before_action :set_user
      rescue_from ArgumentError, with: :bad_request

      # POST /api/v1/users/:user_id/sleep_records/clock_in
      def clock_in
        # 檢查使用者是否已經有進行中的睡眠紀錄
        if @user.current_sleep_record.present?
          render json: {
            error: '使用者已有進行中的睡眠紀錄',
            current_sleep_record: {
              id: @user.current_sleep_record.id,
              bed_time: @user.current_sleep_record.bed_time
            }
          }, status: :unprocessable_entity
          return
        end

        # 建立新的睡眠紀錄
        @sleep_record = @user.sleep_records.build(bed_time: Time.current)

        if @sleep_record.save
          render json: {
            message: '打卡成功',
            sleep_record: {
              id: @sleep_record.id,
              bed_time: @sleep_record.bed_time,
              status: 'ongoing'
            }
          }, status: :created
        else
          render json: {
            error: '打卡失敗',
            errors: @sleep_record.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/users/:user_id/sleep_records
      def index
        page = (params[:page] || 1).to_i
        per_page = [(params[:per_page] || 20).to_i, 100].min # 限制最大每頁100筆

        with_read_replica do
          @sleep_records = @user.sleep_records.recent.offset((page - 1) * per_page).limit(per_page)
          @total_count = @user.sleep_records.count
        end

        render json: {
          user_id: @user.id,
          user_name: @user.name,
          pagination: {
            current_page: page,
            per_page: per_page,
            total_count: @total_count,
            total_pages: (@total_count.to_f / per_page).ceil,
            has_next_page: page < (@total_count.to_f / per_page).ceil,
            has_prev_page: page > 1
          },
          sleep_records: @sleep_records.map do |record|
            {
              id: record.id,
              bed_time: record.bed_time,
              wake_up_time: record.wake_up_time,
              duration_in_seconds: record.duration_in_seconds,
              duration_in_hours: record.duration_in_hours,
              status: record.ongoing? ? 'ongoing' : 'completed',
              created_at: record.created_at
            }
          end
        }
      end

      # PATCH /api/v1/users/:user_id/sleep_records/wake_up
      def wake_up
        # 檢查使用者是否有進行中的睡眠紀錄
        @current_sleep_record = @user.current_sleep_record

        unless @current_sleep_record
          render json: {
            error: '使用者沒有進行中的睡眠紀錄'
          }, status: :unprocessable_entity
          return
        end

        @current_sleep_record.wake_up_time = Time.current
        if @current_sleep_record.save
          render json: {
            message: '起床打卡成功',
            sleep_record: {
              id: @current_sleep_record.id,
              bed_time: @current_sleep_record.bed_time,
              wake_up_time: @current_sleep_record.wake_up_time,
              duration_in_seconds: @current_sleep_record.duration_in_seconds,
              duration_in_hours: @current_sleep_record.duration_in_hours,
              status: 'completed'
            }
          }, status: :ok
        else
          render json: {
            error: '起床打卡失敗',
            errors: @current_sleep_record.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/users/:user_id/sleep_records/friends_sleep_feed
      def friends_sleep_feed
        page = (params[:page] || 1).to_i
        per_page = [(params[:per_page] || 20).to_i, 100].min # 限制最大每頁100筆

        with_read_replica do
          @friends_sleep_records = SleepRecord.friends_sleep_feed(
            follower_id: @user.id,
            start_date: 1.week.ago.beginning_of_week,
            end_date: 1.week.ago.end_of_week,
            page: page,
            per_page: per_page
          )

          @total_count = SleepRecord.friends_sleep_feed(
            follower_id: @user.id,
            start_date: 1.week.ago.beginning_of_week,
            end_date: 1.week.ago.end_of_week
          ).count
        end

        render json: {
          user_id: @user.id,
          user_name: @user.name,
          time_range: {
            start_date: 1.week.ago.beginning_of_week,
            end_date: 1.week.ago.end_of_week
          },
          pagination: {
            current_page: page,
            per_page: per_page,
            total_count: @total_count,
            total_pages: (@total_count.to_f / per_page).ceil,
            has_next_page: page < (@total_count.to_f / per_page).ceil,
            has_prev_page: page > 1
          },
          total_records: @friends_sleep_records.count,
          friends_sleep_records: @friends_sleep_records.map do |record|
            {
              id: record.id,
              user: {
                id: record.user_id,
                name: record.user.name
              },
              bed_time: record.bed_time,
              wake_up_time: record.wake_up_time,
              duration_in_seconds: record.duration_in_seconds,
              duration_in_hours: record.duration_in_hours,
              created_at: record.created_at
            }
          end
        }
      end

      private

      def set_user
        @user = User.find(params[:user_id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: '使用者不存在',
          details: "找不到 ID 為 #{params[:user_id]} 的使用者"
        }, status: :not_found
        return
      end
    end
  end
end
