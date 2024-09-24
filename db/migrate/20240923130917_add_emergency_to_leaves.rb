class AddEmergencyToLeaves < ActiveRecord::Migration[7.0]
  def change
    add_column :leaves, :emergency, :boolean, default: false
  end
end
