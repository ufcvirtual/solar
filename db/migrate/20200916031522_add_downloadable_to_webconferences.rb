class AddDownloadableToWebconferences < ActiveRecord::Migration
  def change
    add_column :webconferences, :downloadable, :boolean, default: false
  end
end
