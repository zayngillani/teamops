class CreateAttendances < ActiveRecord::Migration[7.0]
  def change
    create_table :attendances do |t|
      t.datetime :check_in_time
      t.datetime :check_out_time
      t.datetime :break_in_time
      t.datetime :break_out_time
      t.integer :total_hours

      t.timestamps
    end
  end
end
