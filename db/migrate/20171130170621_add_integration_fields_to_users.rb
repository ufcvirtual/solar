class AddIntegrationFieldsToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :previous_username
      t.string :previous_email
      t.boolean :selfregistration, default: false, null: false
    end
  end
end
