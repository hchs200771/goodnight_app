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

  describe 'GET /api/v1/users/:user_id/sleep_records/friends_sleep_feed' do
    let(:friend1) { create(:user) }
    let(:friend2) { create(:user) }
    let(:non_friend) { create(:user) }

    before do
      # 建立追蹤關係
      user.follow(friend1)
      user.follow(friend2)

      # 建立上週的睡眠紀錄
      travel_to(1.week.ago + 1.day) do
        # 使用 build + save 來避免回調覆蓋 duration_in_seconds
        @friend2_record = build(:sleep_record, user: friend2, bed_time: 9.hours.ago, wake_up_time: Time.current)
        @friend2_record.duration_in_seconds = 32400 # 9小時
        @friend2_record.save!

        @friend1_record1 = build(:sleep_record, user: friend1, bed_time: 8.hours.ago, wake_up_time: Time.current)
        @friend1_record1.duration_in_seconds = 28800 # 8小時
        @friend1_record1.save!

        @friend1_record2 = build(:sleep_record, user: friend1, bed_time: 7.hours.ago, wake_up_time: Time.current)
        @friend1_record2.duration_in_seconds = 25200 # 7小時
        @friend1_record2.save!

        @non_friend_record = build(:sleep_record, user: non_friend, bed_time: 10.hours.ago, wake_up_time: Time.current)
        @non_friend_record.duration_in_seconds = 36000 # 10小時
        @non_friend_record.save!
      end

      # 建立本週的睡眠紀錄（不應該出現在結果中）
      travel_to(Time.current) do
        @current_week_record = create(:sleep_record, :completed, user: friend1, duration_in_seconds: 30000)
      end
    end

    context 'when user has friends with sleep records' do
      it 'returns friends sleep records from last week' do
        get "/api/v1/users/#{user.id}/sleep_records/friends_sleep_feed"

        expect(response).to have_http_status(:ok)

        # 檢查基本結構
        expect(parsed_response_body['user_id']).to eq(user.id)
        expect(parsed_response_body['user_name']).to eq(user.name)
        expect(parsed_response_body['total_records']).to eq(3)
        expect(parsed_response_body['friends_sleep_records']).to have_attributes(length: 3)

        # 檢查時間範圍
        expect(parsed_response_body['time_range']).to include(
          'start_date' => be_present,
          'end_date' => be_present
        )

        # 檢查分頁資訊
        expect(parsed_response_body['pagination']).to include(
          'current_page' => 1,
          'per_page' => 20,
          'total_count' => 3,
          'total_pages' => 1,
          'has_next_page' => false,
          'has_prev_page' => false
        )

        # 檢查是否包含所有朋友的睡眠紀錄
        records = parsed_response_body['friends_sleep_records']
        expect(records.map { |r| r['id'] }).to eq([@friend2_record.id, @friend1_record1.id, @friend1_record2.id])
      end

      it 'supports pagination with page 1 and per_page 2' do
        get "/api/v1/users/#{user.id}/sleep_records/friends_sleep_feed?page=1&per_page=2"

        expect(response).to have_http_status(:ok)

        # 檢查基本結構
        expect(parsed_response_body['user_id']).to eq(user.id)
        expect(parsed_response_body['user_name']).to eq(user.name)
        expect(parsed_response_body['total_records']).to eq(2)  # 每頁 2 筆
        expect(parsed_response_body['friends_sleep_records']).to have_attributes(length: 2)

        # 檢查分頁資訊
        expect(parsed_response_body['pagination']).to include(
          'current_page' => 1,
          'per_page' => 2,
          'total_count' => 3,  # 總數仍然是 3
          'total_pages' => 2,  # 總頁數：3/2 = 2 頁
          'has_next_page' => true,   # 有下一頁
          'has_prev_page' => false   # 第一頁沒有上一頁
        )

        # 檢查第一頁的資料（應該是前 2 筆，按睡眠時長降序）
        records = parsed_response_body['friends_sleep_records']

        # 第一筆應該是最長睡眠時間（32400 秒）
        # 第二筆應該是第二長睡眠時間（28800 秒）
        durations = records.map { |r| r['duration_in_seconds'] }
        expect(durations).to eq([32400, 28800])
      end

      it 'supports pagination with page 2 and per_page 2' do
        get "/api/v1/users/#{user.id}/sleep_records/friends_sleep_feed?page=2&per_page=2"

        expect(response).to have_http_status(:ok)

        # 檢查基本結構
        expect(parsed_response_body['user_id']).to eq(user.id)
        expect(parsed_response_body['user_name']).to eq(user.name)
        expect(parsed_response_body['total_records']).to eq(1)  # 第二頁只有 1 筆
        expect(parsed_response_body['friends_sleep_records']).to have_attributes(length: 1)

        # 檢查分頁資訊
        expect(parsed_response_body['pagination']).to include(
          'current_page' => 2,
          'per_page' => 2,
          'total_count' => 3,  # 總數仍然是 3
          'total_pages' => 2,  # 總頁數：3/2 = 2 頁
          'has_next_page' => false,  # 最後一頁沒有下一頁
          'has_prev_page' => true    # 第二頁有上一頁
        )

        # 檢查第二頁的資料（應該是最後 1 筆）
        durations = parsed_response_body['friends_sleep_records'].map { |r| r['duration_in_seconds'] }
        expect(durations).to eq([25200])
      end

      it 'handles pagination edge cases correctly' do
        # 測試超出範圍的頁碼
        get "/api/v1/users/#{user.id}/sleep_records/friends_sleep_feed?page=3&per_page=2"

        expect(response).to have_http_status(:ok)

        # 檢查基本結構
        expect(parsed_response_body['user_id']).to eq(user.id)
        expect(parsed_response_body['user_name']).to eq(user.name)
        expect(parsed_response_body['total_records']).to eq(0)  # 超出範圍，沒有資料
        expect(parsed_response_body['friends_sleep_records']).to eq([])

        # 檢查分頁資訊（超出範圍時，total_count 和 total_pages 保持正確）
        expect(parsed_response_body['pagination']).to include(
          'current_page' => 3,
          'per_page' => 2,
          'total_count' => 3,  # 總數保持正確
          'total_pages' => 2,  # 總頁數：3/2 = 2 頁
          'has_next_page' => false,  # 沒有下一頁
          'has_prev_page' => true    # 有上一頁
        )

        # 測試每頁 1 筆的情況
        get "/api/v1/users/#{user.id}/sleep_records/friends_sleep_feed?page=1&per_page=1"

        expect(response).to have_http_status(:ok)
        expect(parsed_response_body['total_records']).to eq(1)
        expect(parsed_response_body['pagination']).to include(
          'current_page' => 1,
          'per_page' => 1,
          'total_count' => 3,
          'total_pages' => 3,  # 總頁數：3/1 = 3 頁
          'has_next_page' => true,
          'has_prev_page' => false
        )
      end

      it 'orders records by duration_in_seconds in descending order' do
        get "/api/v1/users/#{user.id}/sleep_records/friends_sleep_feed"

        records = parsed_response_body['friends_sleep_records']
        expect(records.length).to eq(3)

        # 檢查排序：應該按照 duration_in_seconds 降序排列
        durations = records.map { |r| r['duration_in_seconds'] }

        # 檢查具體的排序結果
        expect(durations).to eq([32400, 28800, 25200])
      end

      it 'excludes non-friend sleep records' do
        get "/api/v1/users/#{user.id}/sleep_records/friends_sleep_feed"

        records = parsed_response_body['friends_sleep_records']
        record_ids = records.map { |r| r['id'] }

        expect(record_ids).not_to include(@non_friend_record.id)
      end

      it 'excludes current week sleep records' do
        get "/api/v1/users/#{user.id}/sleep_records/friends_sleep_feed"

        records = parsed_response_body['friends_sleep_records']
        record_ids = records.map { |r| r['id'] }

        expect(record_ids).not_to include(@current_week_record.id)
      end

      it 'only includes completed sleep records' do
        # 建立一筆進行中的睡眠紀錄
        travel_to(1.week.ago + 1.day) do
          create(:sleep_record, :ongoing, user: friend1)
        end

        get "/api/v1/users/#{user.id}/sleep_records/friends_sleep_feed"

        records = parsed_response_body['friends_sleep_records']
        expect(records.length).to eq(3) # 仍然是3筆，不包括進行中的
      end
    end

    context 'when user has no friends' do
      let(:lonely_user) { create(:user) }

      it 'returns empty list' do
        get "/api/v1/users/#{lonely_user.id}/sleep_records/friends_sleep_feed"

        expect(response).to have_http_status(:ok)
        # 檢查基本結構
        expect(parsed_response_body['user_id']).to eq(lonely_user.id)
        expect(parsed_response_body['user_name']).to eq(lonely_user.name)
        expect(parsed_response_body['total_records']).to eq(0)
        expect(parsed_response_body['friends_sleep_records']).to eq([])

        # 檢查時間範圍
        expect(parsed_response_body['time_range']).to include(
          'start_date' => be_present,
          'end_date' => be_present
        )

        # 檢查分頁資訊
        expect(parsed_response_body['pagination']).to include(
          'current_page' => 1,
          'per_page' => 20,
          'total_count' => 0,
          'total_pages' => 0,
          'has_next_page' => false,
          'has_prev_page' => false
        )
      end
    end

    context 'when user does not exist' do
      it 'returns not found error' do
        get "/api/v1/users/99999/sleep_records/friends_sleep_feed"

        expect(response).to have_http_status(:not_found)
        expect(parsed_response_body).to eq(
          'error' => '使用者不存在',
          'details' => '找不到 ID 為 99999 的使用者'
        )
      end
    end
  end
end
