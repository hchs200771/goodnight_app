module ReadReplica
  extend ActiveSupport::Concern

  private

  def with_read_replica
    # 只在生產環境中使用讀取分離
    if Rails.env.production?
      ActiveRecord::Base.connected_to(role: :reading) do
        yield
      end
    else
      # 在開發和測試環境中直接使用默認連接
      yield
    end
  rescue ActiveRecord::ConnectionNotEstablished => e
    # 如果讀取副本連接失敗，記錄錯誤並回退到默認連接
    Rails.logger.warn "Read replica connection failed: #{e.message}. Falling back to primary database."
    yield
  end
end
