class CreateAgendas < ActiveRecord::Migration
  def self.up
    create_table :agendas do |t|
      t.integer :allocation_tag_id , :null => false
      t.integer :agenda_type_id
      t.string :title, :limit => 255
      t.text :description
      t.date :start
      t.date :end
    end
  end

  def self.down
    drop_table :agendas
  end
end
