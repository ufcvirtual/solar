module CurriculumUnitsHelper

  # Retorna participantes por unidade curricular passada que tenham status ativo
  #   se resp=TRUE, os retornados sao responsaveis pela turma
  #      o perfil responsavel esta marcado na tabela profiles (pode ser mais de um)
  #   busca em allocation_tags groups e offers relacionadas a unidade curricular
  def class_participants (curriculum_unit, flag_resp = false, offers_id = nil, groups_id = nil)
    if curriculum_unit
        participants = User.find(:all,
          :select => "DISTINCT users.id, users.name as username, users.photo_file_name, users.email, profiles.name as profilename, profiles.id as profileid ",
          :joins => "JOIN allocations on allocations.users_id = users.id
                     JOIN profiles on allocations.profiles_id = profiles.id
                     JOIN allocation_tags on allocations.allocation_tags_id = allocation_tags.id",
          :conditions => "profiles.class_responsible = #{flag_resp} AND
                    allocations.status=#{Allocation_Activated} AND
                    (
                     allocation_tags.curriculum_units_id=#{curriculum_unit} OR
                     allocation_tags.offers_id in (#{offers_id.nil? ? 'NULL' : offers_id}) OR
                     allocation_tags.groups_id in (#{groups_id.nil? ? 'NULL' : groups_id})
                    )",
          :order => "profilename, users.name"
        )
        return participants
    else
        return nil
    end
  end

end
