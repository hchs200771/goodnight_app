require 'rails_helper'

RSpec.describe Api::V1::SleepRecordsController, type: :request do
  let(:user) { create(:user) }

  describe 'POST /api/v1/users/:user_id/sleep_records/clock_in' do
    context 'when user exists' do
      context 'when user has no ongoing sleep record' do
        it 'creates a new sleep record' do
          expect {
            post "/api/v1/users/#{user.id}/sleep_records/clock_in"
          }.to change { user.sleep_records.count }.by(1)
        end

        it 'sets bed_time to current time and returns the created sleep record' do
          travel_to Time.current do
            post "/api/v1/users/#{user.id}/sleep_records/clock_in"

            expect(response).to have_http_status(:created)
            sleep_record = user.sleep_records.last
            expect(sleep_record.bed_time).to be_within(1.second).of(Time.current)
            expect(sleep_record.wake_up_time).to be_nil

            expect(parsed_response_body['message']).to eq('打卡成功')
            expect(parsed_response_body['sleep_record']).to include(
              'bed_time' => user.sleep_records.last.bed_time.as_json,
              'status' => 'ongoing'
            )
          end
        end
      end

      context 'when user already has an ongoing sleep record' do
        let!(:ongoing_record) { create(:sleep_record, :ongoing, user: user) }

        it 'does not create a new sleep record' do
          expect {
            post "/api/v1/users/#{user.id}/sleep_records/clock_in"
          }.not_to change { user.sleep_records.count }
        end

        it 'returns an error message' do
          post "/api/v1/users/#{user.id}/sleep_records/clock_in"

          expect(response).to have_http_status(:unprocessable_entity)
          expect(parsed_response_body['error']).to eq('使用者已有進行中的睡眠紀錄')
          expect(parsed_response_body['current_sleep_record']).to include(
            'id' => ongoing_record.id,
            'bed_time' => ongoing_record.bed_time.as_json
          )
        end
      end
    end

    context 'when user does not exist' do
      it 'returns not found error' do
        post "/api/v1/users/99999/sleep_records/clock_in"

        expect(response).to have_http_status(:not_found)
        expect(parsed_response_body['error']).to eq('使用者不存在')
        expect(parsed_response_body['details']).to eq('找不到 ID 為 99999 的使用者')
      end
    end
  end

  describe 'GET /api/v1/users/:user_id/sleep_records' do
    context 'when user exists' do
      let!(:sleep_record_1) { create(:sleep_record, :completed, user: user, created_at: 2.days.ago) }
      let!(:sleep_record_2) { create(:sleep_record, :ongoing, user: user, created_at: 1.day.ago) }
      let!(:sleep_record_3) { create(:sleep_record, :completed, user: user, created_at: Time.current) }

      it 'returns paginated sleep records for the user ordered by created_at desc' do
        get "/api/v1/users/#{user.id}/sleep_records"

        expect(response).to have_http_status(:ok)

        expect(parsed_response_body).to match(
          'user_id' => user.id,
          'user_name' => user.name,
          'pagination' => {
            'current_page' => 1,
            'per_page' => 20,
            'total_count' => 3,
            'total_pages' => 1,
            'has_next_page' => false,
            'has_prev_page' => false
          },
          'sleep_records' => [
            {
              'id' => sleep_record_3.id,
              'bed_time' => be_present,
              'wake_up_time' => be_present,
              'duration_in_seconds' => be_present,
              'duration_in_hours' => be_present,
              'status' => 'completed',
              'created_at' => be_present
            },
            {
              'id' => sleep_record_2.id,
              'bed_time' => be_present,
              'wake_up_time' => nil,
              'duration_in_seconds' => nil,
              'duration_in_hours' => nil,
              'status' => 'ongoing',
              'created_at' => be_present
            },
            {
              'id' => sleep_record_1.id,
              'bed_time' => be_present,
              'wake_up_time' => be_present,
              'duration_in_seconds' => be_present,
              'duration_in_hours' => be_present,
              'status' => 'completed',
              'created_at' => be_present
            }
          ]
        )
      end

      it 'includes correct sleep record details' do
        get "/api/v1/users/#{user.id}/sleep_records"

        expect(parsed_response_body).to include(
          'sleep_records' => array_including(
            hash_including(
              'id' => sleep_record_2.id,
              'status' => 'ongoing',
              'wake_up_time' => nil,
              'duration_in_seconds' => nil
            ),
            hash_including(
              'id' => sleep_record_1.id,
              'status' => 'completed',
              'wake_up_time' => be_present,
              'duration_in_seconds' => be_present,
              'duration_in_hours' => be_present
            )
          )
        )
      end

      it 'handles custom pagination parameters' do
        get "/api/v1/users/#{user.id}/sleep_records", params: { page: 1, per_page: 2 }

        expect(response).to have_http_status(:ok)

        expect(parsed_response_body).to include(
          'pagination' => hash_including(
            'current_page' => 1,
            'per_page' => 2,
            'total_count' => 3,
            'total_pages' => 2,
            'has_next_page' => true,
            'has_prev_page' => false
          ),
          'sleep_records' => have_attributes(length: 2)
        )
      end

      it 'limits per_page to maximum of 100' do
        get "/api/v1/users/#{user.id}/sleep_records", params: { per_page: 200 }

        expect(response).to have_http_status(:ok)

        expect(parsed_response_body).to include(
          'pagination' => hash_including('per_page' => 100)
        )
      end
    end

    context 'when user has no sleep records' do
            it 'returns empty list' do
        get "/api/v1/users/#{user.id}/sleep_records"

        expect(response).to have_http_status(:ok)
        expect(parsed_response_body).to include(
          'sleep_records' => [],
          'pagination' => hash_including('total_count' => 0)
        )
      end
    end

    context 'when user does not exist' do
            it 'returns not found error' do
        get "/api/v1/users/99999/sleep_records"

        expect(response).to have_http_status(:not_found)
        expect(parsed_response_body).to include(
          'error' => '使用者不存在',
          'details' => '找不到 ID 為 99999 的使用者'
        )
      end
    end
  end

  describe 'PATCH /api/v1/users/:user_id/sleep_records/wake_up' do
    context 'when user exists' do
      context 'when user has an ongoing sleep record' do
        let!(:ongoing_record) { create(:sleep_record, :ongoing, user: user) }

        it 'updates the sleep record with wake_up_time' do
          travel_to(Time.current) do
            patch "/api/v1/users/#{user.id}/sleep_records/wake_up"

            expect(response).to have_http_status(:ok)
            expect(parsed_response_body['message']).to eq('起床打卡成功')

            ongoing_record.reload
            expect(ongoing_record.wake_up_time).to be_within(1.second).of(Time.current)
            expect(ongoing_record.duration_in_seconds).to be_present
          end
        end

        it 'returns the updated sleep record with calculated duration' do
          travel_to(Time.current) do
            patch "/api/v1/users/#{user.id}/sleep_records/wake_up"

            response_body = parsed_response_body['sleep_record']
            expect(response_body['id']).to eq(ongoing_record.id)
            expect(response_body['bed_time']).to eq(ongoing_record.bed_time.as_json)
            expect(response_body['wake_up_time']).to be_present
            expect(response_body['duration_in_seconds']).to be_present
            expect(response_body['duration_in_hours']).to be_present
            expect(response_body['status']).to eq('completed')
          end
        end
      end

      context 'when user has no ongoing sleep record' do
        it 'returns an error message' do
          patch "/api/v1/users/#{user.id}/sleep_records/wake_up"

          expect(response).to have_http_status(:unprocessable_entity)
          expect(parsed_response_body['error']).to eq('使用者沒有進行中的睡眠紀錄')
        end
      end
    end

    context 'when user does not exist' do
      it 'returns not found error' do
        patch "/api/v1/users/99999/sleep_records/wake_up"

        expect(response).to have_http_status(:not_found)
        expect(parsed_response_body['error']).to eq('使用者不存在')
        expect(parsed_response_body['details']).to eq('找不到 ID 為 99999 的使用者')
      end
    end
  end
end
