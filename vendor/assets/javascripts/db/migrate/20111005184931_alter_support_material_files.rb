class AlterSupportMaterialFiles < ActiveRecord::Migration
  def self.up
    execute <<-SQL
      ALTER TABLE support_material_files ADD url text;
      ALTER TABLE support_material_files ALTER COLUMN attachment_file_name DROP NOT NULL;
    SQL
  end

  def self.down
    execute <<-SQL
      ALTER TABLE support_material_files REMOVE url;
      ALTER TABLE support_material_files ALTER COLUMN attachment_file_name SET NOT NULL;
    SQL
  end
end