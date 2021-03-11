class CreateRelatedTaggables < ActiveRecord::Migration[5.1]
  def change
    create_table :related_taggables do |t|
      t.boolean :group_status

      t.references :group
      t.integer :group_at_id

      t.references :offer
      t.integer :offer_at_id

      t.references :semester

      t.references :course
      t.integer :course_at_id

      t.references :curriculum_unit
      t.integer :curriculum_unit_at_id

      t.references :curriculum_unit_type
      t.integer :curriculum_unit_type_at_id

      t.integer :offer_schedule_id ## periodo da oferta / pode ser schedule de oferta ou semestre
    end

    #add_index :related_taggables, :group_id # erro de indice ja criado, pois o metodo t:references já cria um indice para este campo
    add_index :related_taggables, :group_at_id

    #add_index :related_taggables, :offer_id # erro de indice ja criado, pois o metodo t:references já cria um indice para este campo
    add_index :related_taggables, :offer_at_id

    #add_index :related_taggables, :semester_id # erro de indice ja criado, pois o metodo t:references já cria um indice para este campo

    #add_index :related_taggables, :course_id # erro de indice ja criado, pois o metodo t:references já cria um indice para este campo
    add_index :related_taggables, :course_at_id

    #add_index :related_taggables, :curriculum_unit_id # erro de indice ja criado, pois o metodo t:references já cria um indice para este campo
    add_index :related_taggables, :curriculum_unit_at_id

    #add_index :related_taggables, :curriculum_unit_type_id # erro de indice ja criado, pois o metodo t:references já cria um indice para este campo
    add_index :related_taggables, :curriculum_unit_type_at_id

    add_index :related_taggables, :offer_schedule_id
  end
end
