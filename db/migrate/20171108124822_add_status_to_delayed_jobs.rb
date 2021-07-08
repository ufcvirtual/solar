class AddStatusToDelayedJobs < ActiveRecord::Migration[5.1]
  def change
    add_column :delayed_jobs, :status, :boolean, default: false
  end
end
