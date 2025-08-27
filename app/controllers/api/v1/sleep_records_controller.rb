module Api
  module V1
    class SleepRecordsController < ApplicationController
      before_action :set_user

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
