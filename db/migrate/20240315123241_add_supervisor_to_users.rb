class AddSupervisorToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :supervisor, :string
  end
end
