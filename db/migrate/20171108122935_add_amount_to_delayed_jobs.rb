class AddAmountToDelayedJobs < ActiveRecord::Migration
  def change
    add_column :delayed_jobs, :amount, :integer
  end
end
