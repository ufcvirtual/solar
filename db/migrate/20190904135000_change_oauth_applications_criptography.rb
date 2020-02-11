class ChangeOauthApplicationsCriptography < ActiveRecord::Migration
  def change
    change_table :oauth_applications do |t|
      t.string :cryptography
    end
  end
end
