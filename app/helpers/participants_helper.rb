module ParticipantsHelper

  # Retorna responsaveis por unidade curricular passada que tenham status ativo
  #   o perfil responsavel esta marcado na tabela profiles (pode ser mais de um)
  #   busca em allocation_tags groups e offers relacionadas a unidade curricular
  # *** EM DESUSO *** REMOVER ***
  def class_responsible (curriculum_unit)
    if curriculum_unit
        responsible = User.find(:all,
          :select => "DISTINCT users.id, users.name as username, users.photo_file_name, users.email, profiles.name as profilename, profiles.id as profileid ",
          :joins => "inner join allocations on allocations.users_id = users.id
                     inner join profiles on allocations.profiles_id = profiles.id
                     inner join allocation_tags on allocations.allocation_tags_id = allocation_tags.id",
          :conditions => "profiles.class_responsible = TRUE and
                    allocations.status=#{Allocation_Activated} and
                    (
                     allocation_tags.curriculum_units_id=#{curriculum_unit} or
                     allocation_tags.offers_id in (select id from offers where curriculum_units_id=#{curriculum_unit}) or
                     allocation_tags.groups_id in (select groups.id from groups
                                     inner join offers on groups.offers_id=offers.id
                                     where curriculum_units_id=#{curriculum_unit})
                    )",
          :order => "profilename, users.name"
        )
        return responsible
    else
        return nil
    end
  end

  # Retorna participantes por unidade curricular passada que tenham status ativo
  #   se resp=TRUE, os retornados sao responsaveis pela turma
  #      o perfil responsavel esta marcado na tabela profiles (pode ser mais de um)
  #   busca em allocation_tags groups e offers relacionadas a unidade curricular
  def class_participants (curriculum_unit, flag_resp)
    if curriculum_unit
        participants = User.find(:all,
          :select => "DISTINCT users.id, users.name as username, users.photo_file_name, users.email, profiles.name as profilename, profiles.id as profileid ",
          :joins => "inner join allocations on allocations.users_id = users.id
                     inner join profiles on allocations.profiles_id = profiles.id
                     inner join allocation_tags on allocations.allocation_tags_id = allocation_tags.id",
          :conditions => "profiles.class_responsible = #{flag_resp} and
                    allocations.status=#{Allocation_Activated} and
                    (
                     allocation_tags.curriculum_units_id=#{curriculum_unit} or
                     allocation_tags.offers_id in (select id from offers where curriculum_units_id=#{curriculum_unit}) or
                     allocation_tags.groups_id in (select groups.id from groups
                                     inner join offers on groups.offers_id=offers.id
                                     where curriculum_units_id=#{curriculum_unit})
                    )",
          :order => "profilename, users.name"
        )
        return participants
    else
        return nil
    end
  end
  
end
