class DataUpdateResourcesAndPermissionsAddSemester < ActiveRecord::Migration
  def up
    Resource.find(95).update_attributes!({controller: 'semesters', action: 'index', description: 'Listagem de semestres e ofertas a partir da uc e curso selecionados'})

    Resource.create({id: 120, controller: 'semesters', action: 'create', description: 'Novo semestre'}, without_protection: true)
    Resource.create({id: 121, controller: 'semesters', action: 'update', description: 'Atualizar semestre'}, without_protection: true)
    Resource.create({id: 122, controller: 'semesters', action: 'destroy', description: 'Remover semestre'}, without_protection: true)

    PermissionsResource.create({profile_id: 5, resource_id: 120, per_id: false})
    PermissionsResource.create({profile_id: 5, resource_id: 121, per_id: false})
    PermissionsResource.create({profile_id: 5, resource_id: 122, per_id: false})
  end

  def down
    Resource.find(95).update_attributes!({controller: 'offers'})

    PermissionsResource.delete_all(resource_id: [120, 121, 122])
    Resource.where(id: [120, 121, 122]).map(&:destroy)
  end
end
