class CreateEducationalTools < ActiveRecord::Migration
  #Tabela que vincula a allocation_tag a [discussion,assignment, lesson etc]
  def up
    create_table :educational_tools do |t|
      t.references :allocation_tag
      t.foreign_key :allocation_tags
      t.references :educational_tool, :polymorphic => true
    end    
  end

  def down
     drop_table :educational_tools
  end
end
