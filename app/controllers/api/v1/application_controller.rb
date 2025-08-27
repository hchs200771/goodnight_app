module Api
  module V1
    class ApplicationController < ActionController::API
      # API 基礎設定
      include ActionController::HttpAuthentication::Token::ControllerMethods

      # 錯誤處理
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ArgumentError, with: :bad_request

      private

      def not_found(exception)
        # 只處理通用的 RecordNotFound，讓個別 Controller 處理業務邏輯
        render json: {
          error: "資源不存在",
          details: exception.message
        }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: {
          error: "驗證失敗",
          errors: exception.record.errors.full_messages
        }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render json: {
          error: "請求參數錯誤",
          details: exception.message
        }, status: :bad_request
      end
    end
  end
end
