class CreatePublicLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :public_links do |t|
      t.string :token
      t.datetime :expires_at
      t.references :interview, null: false, foreign_key: true

      t.timestamps
    end
  end
end
