class AddSlackMemberIdToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :slack_member_id, :string
  end
end
