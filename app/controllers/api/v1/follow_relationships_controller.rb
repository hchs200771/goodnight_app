module Api
  module V1
    class FollowRelationshipsController < ApplicationController
      include ReadReplica

      before_action :set_user

      # POST /api/v1/users/:user_id/follow
      def create
        followed_id = params[:followed_id]

        # 檢查是否要追蹤自己
        if @user.id.to_s == followed_id.to_s
          render json: {
            error: '不能追蹤自己'
          }, status: :unprocessable_entity
          return
        end

        # 檢查要追蹤的使用者是否存在
        begin
          followed_user = User.find(followed_id)
        rescue ActiveRecord::RecordNotFound
          render json: {
            error: '要追蹤的使用者不存在'
          }, status: :not_found
          return
        end

        # 檢查是否已經追蹤過
        if @user.following?(followed_user)
          render json: {
            error: '已經追蹤過此使用者'
          }, status: :unprocessable_entity
          return
        end

        # 建立追蹤關係
        follow_relationship = @user.following_relationships.build(followed: followed_user)

        if follow_relationship.save
          render json: {
            message: '追蹤成功',
            follow_relationship: {
              id: follow_relationship.id,
              follower_id: @user.id,
              followed_id: followed_user.id,
              created_at: follow_relationship.created_at
            }
          }, status: :created
        else
          render json: {
            error: '追蹤失敗',
            errors: follow_relationship.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/users/:follower_id/follow_relationships/:id
      def destroy
        followed_id = params[:id]

        # 檢查要取消追蹤的使用者是否存在
        begin
          followed_user = User.find(followed_id)
        rescue ActiveRecord::RecordNotFound
          render json: {
            error: '要取消追蹤的使用者不存在'
          }, status: :not_found
          return
        end

        # 檢查是否正在追蹤該使用者
        unless @user.following?(followed_user)
          render json: {
            error: '沒有追蹤此使用者，無法取消追蹤'
          }, status: :unprocessable_entity
          return
        end

        # 取消追蹤
        follow_relationship = @user.following_relationships.find_by(followed: followed_user)

        if follow_relationship.destroy
          render json: {
            message: '取消追蹤成功',
            unfollowed_user: {
              id: followed_user.id,
              name: followed_user.name
            }
          }, status: :ok
        else
          render json: {
            error: '取消追蹤失敗',
            errors: follow_relationship.errors.full_messages
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
