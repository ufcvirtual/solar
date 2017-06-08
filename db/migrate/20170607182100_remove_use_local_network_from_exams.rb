class RemoveUseLocalNetworkFromExams < ActiveRecord::Migration
  def up
    remove_column :exams, :use_local_network
  end

  def down
    add_column :exams, :use_local_network, :boolean
  end
end
