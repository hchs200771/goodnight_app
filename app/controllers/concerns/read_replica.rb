module ReadReplica
  extend ActiveSupport::Concern

  private

  def with_read_replica
    # 在生產環境中使用讀取分離
    if Rails.env.production?
      ActiveRecord::Base.connected_to(role: :reading) do
        yield
      end
    else
      yield
    end
  end
end
