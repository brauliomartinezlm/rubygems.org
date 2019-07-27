class CreateCredentials < ActiveRecord::Migration[5.2]
  def change
    create_table :credentials do |t|
      t.string :public_key
      t.string :external_id
      t.string :device_name
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
