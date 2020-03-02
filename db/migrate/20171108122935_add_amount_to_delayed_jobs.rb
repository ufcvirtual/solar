class AddAmountToDelayedJobs < ActiveRecord::Migration[5.0]
  def change
    add_column :delayed_jobs, :amount, :integer
  end
end
