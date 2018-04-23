class RemoveCpfMaskFromUsers < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      UPDATE users SET cpf = translate(cpf, '.-', '');
    SQL
  end

  def down
    # do nothing
  end
end
