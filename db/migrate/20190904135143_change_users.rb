class ChangeUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.references :oauth_application, null: true
      t.foreign_key :oauth_applications
    end
  end
end
