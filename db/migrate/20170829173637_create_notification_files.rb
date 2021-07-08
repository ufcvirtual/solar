class CreateNotificationFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :notification_files do |t|
      t.references :notification
      t.attachment :file

      t.timestamps
    end
    #add_index :notification_files, :notification_id # erro de indice ja criado, pois o metodo t:references já cria um indice para este campo
  end
end
