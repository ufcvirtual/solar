class AddDownloadableToWebconferences < ActiveRecord::Migration[5.0]
  def change
    add_column :webconferences, :downloadable, :boolean, default: false
  end
end
