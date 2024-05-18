class CreatePublicHolidays < ActiveRecord::Migration[7.0]
  def change
    create_table :public_holidays do |t|
      t.string :title
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
