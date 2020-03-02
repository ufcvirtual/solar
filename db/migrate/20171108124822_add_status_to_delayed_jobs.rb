class AddStatusToDelayedJobs < ActiveRecord::Migration[5.0]
  def change
    add_column :delayed_jobs, :status, :boolean, default: false
  end
end
