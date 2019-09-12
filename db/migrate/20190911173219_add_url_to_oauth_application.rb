class AddUrlToOauthApplication < ActiveRecord::Migration
  def change
    change_table :oauth_applications do |t|
      t.string :recover_password_url
    end
  end
end
