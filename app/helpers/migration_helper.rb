module MigrationHelper

  def add_foreign_key(from_table, from_column, to_table)
    constraint_name = "fk_#{from_table}_#{from_column}"

    #coloquei ON DELETE CASCADE - ver se coloca UPDATE tb...
    execute %{alter table #{from_table}
              add constraint #{constraint_name}
              foreign key (#{from_column})
              references #{to_table}(id)
              ON DELETE CASCADE}
  end

  def remove_foreign_key(from_table, from_column)
    constraint_name = "fk_#{from_table}_#{from_column}"

    #drop FOREIGN KEY nao funcionou... troquei por CONSTRAINT
    execute %{alter table #{from_table}
              drop CONSTRAINT #{constraint_name}}
  end

end
