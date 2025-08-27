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
