class AddJobPostToJobApplications < ActiveRecord::Migration[7.0]
  def change
    add_reference :job_applications, :job_post, foreign_key: true
  end
end
