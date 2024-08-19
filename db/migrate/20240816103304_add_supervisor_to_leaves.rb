class AddSupervisorToLeaves < ActiveRecord::Migration[7.0]
  def change
    add_column :leaves, :supervisor, :string
    add_column :leaves, :leave_type, :integer
  end
end
