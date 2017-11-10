class AddStatusToDelayedJobs < ActiveRecord::Migration
  def change
    add_column :delayed_jobs, :status, :boolean, default: false
  end
end
