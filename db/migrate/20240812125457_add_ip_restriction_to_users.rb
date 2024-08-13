class AddIpRestrictionToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :can_outside_access, :boolean, default: false
  end
end
