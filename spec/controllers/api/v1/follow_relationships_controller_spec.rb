require 'rails_helper'

RSpec.describe Api::V1::FollowRelationshipsController, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'POST /api/v1/users/:user_id/follow_relationships' do
    context 'when user exists' do
      context 'when following another user' do
        it 'creates a follow relationship' do
          expect {
            post "/api/v1/users/#{user.id}/follow_relationships",
                 params: { followed_id: other_user.id }
          }.to change { user.following.count }.by(1)
        end

        it 'returns success response' do
          post "/api/v1/users/#{user.id}/follow_relationships",
               params: { followed_id: other_user.id }

          expect(response).to have_http_status(:created)
          expect(parsed_response_body).to match(
            'message' => '追蹤成功',
            'follow_relationship' => {
              'id' => be_present,
              'follower_id' => user.id,
              'followed_id' => other_user.id,
              'created_at' => be_present
            }
          )
        end

        it 'updates following status' do
          post "/api/v1/users/#{user.id}/follow_relationships",
               params: { followed_id: other_user.id }

          expect(user.reload.following?(other_user)).to be true
        end
      end

      context 'when trying to follow self' do
        it 'returns error' do
          post "/api/v1/users/#{user.id}/follow_relationships",
               params: { followed_id: user.id }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(parsed_response_body).to eq(
            'error' => '不能追蹤自己'
          )
        end

        it 'does not create follow relationship' do
          expect {
            post "/api/v1/users/#{user.id}/follow_relationships",
                 params: { followed_id: user.id }
          }.not_to change { user.following.count }
        end
      end

      context 'when trying to follow non-existent user' do
        it 'returns not found error' do
          post "/api/v1/users/#{user.id}/follow_relationships",
               params: { followed_id: 99999 }

          expect(response).to have_http_status(:not_found)
          expect(parsed_response_body).to eq(
            'error' => '要追蹤的使用者不存在'
          )
        end

        it 'does not create follow relationship' do
          expect {
            post "/api/v1/users/#{user.id}/follow_relationships",
                 params: { followed_id: 99999 }
          }.not_to change { user.following.count }
        end
      end

      context 'when already following the user' do
        before do
          user.follow(other_user)
        end

        it 'returns error' do
          post "/api/v1/users/#{user.id}/follow_relationships",
               params: { followed_id: other_user.id }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(parsed_response_body).to eq(
            'error' => '已經追蹤過此使用者'
          )
        end

        it 'does not create duplicate follow relationship' do
          expect {
            post "/api/v1/users/#{user.id}/follow_relationships",
                 params: { followed_id: other_user.id }
          }.not_to change { user.following.count }
        end
      end
    end

    context 'when user does not exist' do
      it 'returns not found error' do
        post "/api/v1/users/99999/follow_relationships",
             params: { followed_id: other_user.id }

        expect(response).to have_http_status(:not_found)
        expect(parsed_response_body).to eq(
          'error' => '使用者不存在',
          'details' => '找不到 ID 為 99999 的使用者'
        )
      end
    end
  end

  describe 'DELETE /api/v1/users/:follower_id/follow_relationships/:id' do
    context 'when user exists' do
      context 'when unfollowing a followed user' do
        before do
          user.follow(other_user)
        end

        it 'removes the follow relationship' do
          expect {
            delete "/api/v1/users/#{user.id}/follow_relationships/#{other_user.id}"
          }.to change { user.following.count }.by(-1)
        end

        it 'returns success response' do
          delete "/api/v1/users/#{user.id}/follow_relationships/#{other_user.id}"

          expect(response).to have_http_status(:ok)
          expect(parsed_response_body).to match(
            'message' => '取消追蹤成功',
            'unfollowed_user' => {
              'id' => other_user.id,
              'name' => other_user.name
            }
          )
        end

        it 'updates following status' do
          delete "/api/v1/users/#{user.id}/follow_relationships/#{other_user.id}"

          expect(user.reload.following?(other_user)).to be false
        end
      end

      context 'when trying to unfollow a non-followed user' do
        it 'returns error' do
          delete "/api/v1/users/#{user.id}/follow_relationships/#{other_user.id}"

          expect(response).to have_http_status(:unprocessable_entity)
          expect(parsed_response_body).to eq(
            'error' => '沒有追蹤此使用者，無法取消追蹤'
          )
        end

        it 'does not change follow relationships count' do
          expect {
            delete "/api/v1/users/#{user.id}/follow_relationships/#{other_user.id}"
          }.not_to change { user.following.count }
        end
      end

      context 'when trying to unfollow non-existent user' do
        it 'returns not found error' do
          delete "/api/v1/users/#{user.id}/follow_relationships/99999"

          expect(response).to have_http_status(:not_found)
          expect(parsed_response_body).to eq(
            'error' => '要取消追蹤的使用者不存在'
          )
        end

        it 'does not change follow relationships count' do
          expect {
            delete "/api/v1/users/#{user.id}/follow_relationships/99999"
          }.not_to change { user.following.count }
        end
      end
    end

    context 'when user does not exist' do
      it 'returns not found error' do
        delete "/api/v1/users/99999/follow_relationships/#{other_user.id}"

        expect(response).to have_http_status(:not_found)
        expect(parsed_response_body).to eq(
          'error' => '使用者不存在',
          'details' => '找不到 ID 為 99999 的使用者'
        )
      end
    end
  end
end
