class CreateJobPosts < ActiveRecord::Migration[7.0]
  def change
    create_table :job_posts do |t|
      t.string :title
      t.text :details
      t.integer :job_status, default: 0
      t.text :requirements_and_qualification

      t.timestamps
    end
  end
end
