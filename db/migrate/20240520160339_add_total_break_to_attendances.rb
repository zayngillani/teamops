class AddTotalBreakToAttendances < ActiveRecord::Migration[7.0]
  def change
    add_column :attendances, :total_break, :integer
  end
end
