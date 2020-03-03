class AddSupportToMessage < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :support, :string
  end
end
