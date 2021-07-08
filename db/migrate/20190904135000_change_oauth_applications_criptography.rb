class ChangeOauthApplicationsCriptography < ActiveRecord::Migration[5.0]
  def change
    change_table :oauth_applications do |t|
      t.string :cryptography
    end
  end
end
