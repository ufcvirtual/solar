class CreateEducationalTools < ActiveRecord::Migration[5.1]
  #Tabela que vincula a allocation_tag a [discussion,assignment, lesson etc]
  def self.up
    create_table :educational_tools do |t|
      t.references :allocation_tag
      t.foreign_key :allocation_tags
      t.references :educational_tool, :polymorphic => true, index: { name: 'index_educational_tool_type_and_educational_tool_id' } # renomendo o indice pois gerado automatica estava ultrapassando a quantidade de caracteres permitidos ocasionando erro.
    end    
  end

  def self.down
     drop_table :educational_tools
  end
end
