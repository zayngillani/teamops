class CreateContactDetails < ActiveRecord::Migration[7.0]
  def change
    create_table :contact_details do |t|
      t.jsonb :details, default: {}

      t.timestamps
    end
  end
end
