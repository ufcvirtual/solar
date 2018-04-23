class RemoveUseLocalNetworkFromExams < ActiveRecord::Migration[5.0]
  def up
    remove_column :exams, :use_local_network
  end

  def down
    add_column :exams, :use_local_network, :boolean
  end
end
