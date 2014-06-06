class RemoveCpfMaskFromUsers < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE users SET cpf = translate(cpf, '.-', '');
    SQL
  end

  def down
    # do nothing
  end
end
