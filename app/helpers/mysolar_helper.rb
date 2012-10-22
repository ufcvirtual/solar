module MysolarHelper

	##
	# Retorna as unidades curriculares que o usuário atual está relacionado na seguinte ordenação:
	# Maior quantidade de acessos nas últimas 3 semanas > Ter perfil de aluno ou responsável > Nome
	##
  def load_curriculum_unit_data
  	curriculum_units_info = CurriculumUnit.find_default_by_user_id(current_user.id)
    allocation_tags_ids   = curriculum_units_info["allocation_tags_ids"]
  	curriculum_units 			= curriculum_units_info["curriculum_units"].flatten

    # array com o resultado da comparação de bit entre o tipo do perfil do usuário em cada uc e o de responsável/aluno
    # ex.: 
    # perfil do usuário na allocation de uma uc = 2 -> (2 & Profile_Type_Class_Rresponsible) != 0 => true
    # perfil do usuário na allocation de uma uc = 5 -> (5 & Profile_Type_Class_Rresponsible) != 0 => false
    is_responsible_or_student = curriculum_units.enum_for(:each_with_index).collect { |curriculum_unit, idx|   
      profile_types = Allocation.find_by_allocation_tag_id_and_user_id(allocation_tags_ids[idx], current_user.id).profile.types
      ((profile_types & Profile_Type_Class_Responsible) != 0 or (profile_types & Profile_Type_Student) != 0)
    }

    # re-ordena as uc de acordo com o resultado dos tipos de perfil e o nome
  	curriculum_units = curriculum_units.sort_by{ |curriculum_unit|
      curriculum_unit["name"] # a verificação do nome vem primeiro para ser sobreposta pela de maior prioridade
      is_responsible_or_student[curriculum_units.index(curriculum_unit)] ? 0 : 1 
    }

    # re-ordena as uc de acordo com a maior quantidade de acessos nas últimas três semanas
  	curriculum_units = curriculum_units.sort_by{ |curriculum_unit| 
      -(Log.count(:id, :conditions => {:log_type => 3, :user_id => current_user.id, :curriculum_unit_id => curriculum_unit["id"], :created_at => 3.week.ago.to_date..Date.current}))
    }

    # após ordenação, allocation_tags_ids não está ordenado, mas sua presença é desnecessária a partir do momento que pode-se ter "curriculum_unit.allocation_tag.id"
  	return {"curriculum_units" => curriculum_units, "offers" => curriculum_units_info["offers"], "groups" => curriculum_units_info["groups"]}
  end

end
