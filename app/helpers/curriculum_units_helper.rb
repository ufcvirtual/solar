module CurriculumUnitsHelper

  # Retorna participantes por unidade curricular passada que tenham status ativo
  #   se resp=TRUE, os retornados sao responsaveis pela turma
  #      o perfil responsavel esta marcado na tabela profiles (pode ser mais de um)
  #   busca em allocation_tags groups e offers relacionadas a unidade curricular
  def class_participants (curriculum_unit, flag_resp = false, offer_id = nil, group_id = nil)
    if curriculum_unit
        participants = User.find(:all,
          :select => "DISTINCT users.id, users.name as username, users.photo_file_name, users.email, profiles.name as profilename, profiles.id as profileid ",
          :joins => "JOIN allocations on allocations.user_id = users.id
                     JOIN profiles on allocations.profile_id = profiles.id
                     JOIN allocation_tags on allocations.allocation_tag_id = allocation_tags.id",
          :conditions => "profiles.class_responsible = #{flag_resp} AND
                    allocations.status=#{Allocation_Activated} AND
                    (
                     allocation_tags.curriculum_unit_id=#{curriculum_unit} OR
                     allocation_tags.offer_id in (#{offer_id.nil? ? 'NULL' : offer_id}) OR
                     allocation_tags.group_id in (#{group_id.nil? ? 'NULL' : group_id})
                    )",
          :order => "profilename, users.name"
        )
        return participants
    else
        return nil
    end
  end

end
