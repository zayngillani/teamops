class CreateJobApplications < ActiveRecord::Migration[7.0]
  def change
    create_table :job_applications do |t|
      t.string :name
      t.string :email
      t.string :qualification
      t.string :cnic
      t.string :current_experience
      t.string :contact_number
      t.string :current_salary
      t.string :expected_salary
      t.string :resume_link

      t.timestamps
    end
  end
end
