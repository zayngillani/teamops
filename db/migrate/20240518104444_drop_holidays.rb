class DropHolidays < ActiveRecord::Migration[7.0]
  def change
    drop_table :holidays, if_exists: true
  end
end
