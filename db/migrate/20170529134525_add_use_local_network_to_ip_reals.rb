class AddUseLocalNetworkToIpReals < ActiveRecord::Migration
  def change
    add_column :ip_reals, :use_local_network, :boolean, default: false
  end
end
