class AddSupportToMessage < ActiveRecord::Migration
  def change
    add_column :messages, :support, :string
  end
end
