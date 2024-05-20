class CreateBreaks < ActiveRecord::Migration[7.0]
  def change
    create_table :breaks do |t|
      t.references :attendance, null: false, foreign_key: true
      t.datetime :break_in_time
      t.datetime :break_out_time

      t.timestamps
    end
  end
end
