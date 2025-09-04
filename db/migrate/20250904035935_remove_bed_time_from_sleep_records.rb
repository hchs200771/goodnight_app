class RemoveBedTimeFromSleepRecords < ActiveRecord::Migration[7.2]
  def change
    remove_column :sleep_records, :bed_time, :datetime
  end
end
