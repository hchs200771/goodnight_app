# Goodnight App

一個基於 Rails 的睡眠追蹤應用程式，允許使用者追蹤睡眠模式並關注朋友以查看他們的睡眠數據。

## 功能特色

- **睡眠追蹤**：打卡上下班以追蹤睡眠時長
- **社交功能**：關注/取消關注其他使用者以查看他們的睡眠模式
- **睡眠分析**：查看個人睡眠記錄和朋友睡眠動態
- **RESTful API**：乾淨的 API 設計，具有適當的錯誤處理和分頁功能

## 技術架構

- **後端**：Ruby on Rails 7
- **資料庫**：PostgreSQL
- **API**：RESTful JSON API
- **測試**：RSpec 與 FactoryBot

## 資料模型

### User（使用者）
- **屬性**：`id`、`name`、`created_at`、`updated_at`
- **關聯**：
  - 擁有多個睡眠記錄
  - 擁有多個關注關係（他們關注的使用者）
  - 擁有多個粉絲關係（關注他們的使用者）
- **方法**：
  - `follow(user)`：關注另一個使用者
  - `unfollow(user)`：取消關注使用者
  - `following?(user)`：檢查是否關注某使用者
  - `current_sleep_record`：獲取進行中的睡眠記錄

### SleepRecord（睡眠記錄）
- **屬性**：`id`、`user_id`、`bed_time`、`wake_up_time`、`duration_in_seconds`、`created_at`、`updated_at`
- **關聯**：屬於使用者
- **作用域**：
  - `completed`：有起床時間的記錄
  - `ongoing`：沒有起床時間的記錄
  - `by_duration`：按睡眠時長排序
  - `recent`：按創建日期排序
- **方法**：
  - `duration_in_hours`：將秒數轉換為小時
  - `ongoing?`：檢查睡眠是否進行中
- **類方法**：
  - `friends_sleep_feed`：獲取關注使用者的睡眠記錄

### FollowRelationship（關注關係）
- **屬性**：`id`、`follower_id`、`followed_id`、`created_at`、`updated_at`
- **關聯**：屬於關注者和被關注者
- **驗證**：不能關注自己，關注者-被關注者對必須唯一

## API 端點

### 基礎 URL
```
/api/v1
```

### 睡眠記錄

#### 開始睡眠打卡
```http
POST /api/v1/users/:user_id/sleep_records/clock_in
```
**回應**：使用當前時間戳創建新的睡眠記錄

#### 起床打卡
```http
PATCH /api/v1/users/:user_id/sleep_records/wake_up
```
**回應**：更新睡眠記錄的起床時間並計算時長

#### 獲取使用者的睡眠記錄
```http
GET /api/v1/users/:user_id/sleep_records?page=1&per_page=20
```
**查詢參數**：
- `page`：頁碼（預設：1）
- `per_page`：每頁記錄數（預設：20，最大：100）

#### 獲取朋友睡眠動態
```http
GET /api/v1/users/:user_id/sleep_records/friends_sleep_feed?start_date=2024-01-01&end_date=2024-01-07&page=1&per_page=20
```
**查詢參數**：
- `start_date`：範圍開始日期（也可以不給，預設：前一週的開始）
- `end_date`：範圍結束日期（也可以不給，預設：前一週的結束）
- `page`：頁碼（預設：1）
- `per_page`：每頁記錄數（預設：20，最大：100）

### 關注關係

#### 關注使用者
```http
POST /api/v1/users/:user_id/follow_relationships
```
**請求體**：
```json
{
  "followed_id": 123
}
```

#### 取消關注使用者
```http
DELETE /api/v1/users/:user_id/follow_relationships/:followed_id
```

## 資料庫結構

### Users 表
```sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### Sleep Records 表
```sql
CREATE TABLE sleep_records (
  id BIGINT PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  bed_time TIMESTAMP NOT NULL,
  wake_up_time TIMESTAMP,
  duration_in_seconds INTEGER,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

### Follow Relationships 表
```sql
CREATE TABLE follow_relationships (
  id BIGINT PRIMARY KEY,
  follower_id BIGINT NOT NULL REFERENCES users(id),
  followed_id BIGINT NOT NULL REFERENCES users(id),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  UNIQUE(follower_id, followed_id)
);
```

## 開始使用

### 前置需求
- Ruby 3.1.4
- Rails 7.2.2.2
- PostgreSQL

### 安裝步驟

1. 複製專案
```bash
git clone git@github.com:hchs200771/goodnight_app.git
cd goodnight_app
```

2. 安裝依賴
```bash
bundle install
```

3. 設定資料庫
```bash
rails db:create
rails db:migrate
```

4. 啟動伺服器
```bash
rails server
```

### 執行測試
```bash
bundle exec rspec
```

## 效能特色

- **讀取副本支援**：對讀取密集型操作使用讀取副本
- **優化查詢**：高效的資料庫查詢與適當的索引
- **分頁功能**：內建分頁處理大型資料集
- **預載入**：使用 `includes` 防止 N+1 查詢問題
- **複合索引優化**：針對 `friends_sleep_feed` 查詢優化的複合索引
  - `(user_id, created_at, duration_in_seconds)` - 主要查詢優化
  - `(duration_in_seconds, created_at)` - 排序優化
  - `(user_id, created_at)` - 用戶時間範圍查詢優化

## CI/CD 流程

本專案使用 GitHub Actions 進行持續整合和部署，確保代碼質量和穩定性。

### 觸發條件
- **Pull Request**：每次創建或更新 PR 時觸發
- **Push to main**：直接推送到主分支時觸發

### 工作流程

#### 1. 安全掃描 (scan_ruby)
- **工具**：Brakeman
- **目的**：掃描 Rails 應用程式的安全漏洞
- **配置**：`--no-exit-on-warn` 防止警告導致 CI 失敗
- **觸發**：每次 PR 和 push 時執行

#### 2. 代碼品質檢查 (lint)
- **工具**：RuboCop
- **目的**：確保代碼風格一致性和品質
- **輸出格式**：GitHub 格式，便於在 PR 中查看問題
- **觸發**：每次 PR 和 push 時執行

#### 3. 測試執行 (test)
- **環境**：Ubuntu 22.04 + PostgreSQL
- **測試框架**：RSpec
- **數據庫**：PostgreSQL 測試環境
- **命令**：`bundle exec rspec`
- **觸發**：每次 PR 和 push 時執行

### CI 配置檔案
- **位置**：`.github/workflows/ci.yml`
- **配置**：自動化測試、安全掃描、代碼品質檢查
- **狀態徽章**：可在 README 中顯示 CI 狀態

### 本地測試
在提交代碼前，建議在本地執行以下檢查：
```bash
# 運行測試
bundle exec rspec

# 代碼品質檢查
bin/rubocop

# 安全掃描
bin/brakeman
```

## 錯誤處理

API 包含全面的錯誤處理：
- **400 Bad Request**：無效參數或日期範圍
- **404 Not Found**：使用者或資源不存在
- **422 Unprocessable Entity**：驗證錯誤或業務邏輯違規
- **500 Internal Server Error**：伺服器端錯誤

## 貢獻指南

1. Fork 專案
2. 創建功能分支
3. 進行您的更改
4. 為新功能添加測試
5. 提交 Pull Request

## 重要備註

### 認證與權限
**注意：本專案為作業用途，未實作使用者註冊和認證機制**

在實際生產環境中，前後端溝通應該使用：
- **Devise** 或類似認證框架進行使用者管理
- **JWT (JSON Web Token)** 進行身份驗證
- **權限控制** 限制 API 存取權限
- **資安防護** 防止未授權存取和資料洩露

### 當前實作限制
- 所有 API 端點都開放存取，無需認證
- 使用者 ID 直接透過 URL 參數傳遞
- 未實作使用者註冊、登入、登出功能
- 缺乏權限驗證和資料隔離

### 建議的生產環境實作
```ruby
# 使用 Devise + JWT 的範例
class ApplicationController < ActionController::API
  before_action :authenticate_user!
  before_action :verify_jwt_token

  private

  def verify_jwt_token
    # JWT 驗證邏輯
    # 權限檢查
    # 使用者身份確認
  end
end
```
