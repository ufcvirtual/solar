class AddNickWebconferenceOption < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :use_nick_at_webconference, :boolean, default: false
  end
end
