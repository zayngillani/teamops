class AddColumnsToContactDetails < ActiveRecord::Migration[7.0]
  def change
    add_column :contact_details, :contact_type, :string, null: false
    add_column :contact_details, :email, :string
    add_column :contact_details, :contact_no, :string
  end
end
