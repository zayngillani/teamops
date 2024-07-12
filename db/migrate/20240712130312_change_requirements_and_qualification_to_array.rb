class ChangeRequirementsAndQualificationToArray < ActiveRecord::Migration[7.0]
  def change
    remove_column :job_posts, :requirements_and_qualification, :text
    add_column :job_posts, :requirements_and_qualification, :text, array: true, default: []
  end
end
