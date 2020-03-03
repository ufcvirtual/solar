class AddUrlToOauthApplication < ActiveRecord::Migration[5.0]
  def change
    change_table :oauth_applications do |t|
      t.string :recover_password_url
    end
  end
end
