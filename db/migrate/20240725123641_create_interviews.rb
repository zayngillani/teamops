class CreateInterviews < ActiveRecord::Migration[7.0]
  def change
    create_table :interviews do |t|
      t.date :interview_date
      t.time :interview_time
      t.integer :status, default: 0, null: false
      t.integer :result, default: 0, null: false
      t.references :job_application, null: false, foreign_key: true

      t.timestamps
    end
  end
end
