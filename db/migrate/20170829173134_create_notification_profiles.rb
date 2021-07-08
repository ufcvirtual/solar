class CreateNotificationProfiles < ActiveRecord::Migration[5.1]
  def change
    create_table :notification_profiles do |t|
      t.references :profile
      t.references :notification
    end
    # erro de indice ja criado, pois o metodo t:references já cria um indice para estes campos
    #add_index :notification_profiles, :profile_id
    #add_index :notification_profiles, :notification_id
  end
end
