class RemoveIsRejectedAndIsSelectedFromJobApplications < ActiveRecord::Migration[7.0]
  def change
    remove_column :job_applications, :is_rejected
    remove_column :job_applications, :is_selected
  end
end
