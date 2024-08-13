class AddIsRejectedAndInterviewStatusToJobApplications < ActiveRecord::Migration[7.0]
  def change
    add_column :job_applications, :is_rejected, :boolean, default: false
    add_column :job_applications, :is_selected, :boolean, default: false
    add_column :job_applications, :interview_status, :integer, default: 0
  end
end
