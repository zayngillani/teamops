class AddReportToAttendances < ActiveRecord::Migration[7.0]
  def change
    add_column :attendances, :report, :string
  end
end
