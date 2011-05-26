class CreateMessageLabels < ActiveRecord::Migration
  def self.up
    create_table :message_labels do |t|
      t.references :user                                #pode ser de user OU de allocation_tag
      t.references :allocation_tag
      t.string     :title, :null => false, :limit => 120  #mesmo tam max de curriculum_unit
    end
  end

  def self.down
    drop_table :message_labels
  end
end
