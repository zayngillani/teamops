class CreateIpManagement < ActiveRecord::Migration[7.0]
  def change
    create_table :ip_managements do |t|
      t.string :ip_address
      t.string :user_name
      t.integer :status, default: 0 
      t.datetime :deleted_at
      
      t.timestamps
    end
  end
end
