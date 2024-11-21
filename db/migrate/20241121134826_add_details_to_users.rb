class AddDetailsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :address, :string
    add_column :users, :phone_number, :string
    add_column :users, :emergency_phone_number, :string
    add_column :users, :cnic, :string
    add_column :users, :github_user_name, :string
    add_column :users, :date_of_birth, :date
    add_column :users, :personal_email, :string
    add_column :users, :is_github_required, :boolean
  end
end
