class CreateOncalls < ActiveRecord::Migration[7.0]
  def change
    create_table :oncalls do |t|
      t.references :user, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.string :supervisor
      t.string :reason
      t.integer :request_status, default: 0
      t.timestamps
    end
  end
end
