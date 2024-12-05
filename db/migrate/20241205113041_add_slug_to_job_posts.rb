class AddSlugToJobPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :job_posts, :slug, :string
    add_index :job_posts, :slug, unique: true
  end
end
