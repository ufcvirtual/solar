module MysolarHelper

  ##
  # Retorna as unidades curriculares que o usuário atual está relacionado na seguinte ordenação:
  # Maior quantidade de acessos nas últimas 3 semanas > Ter perfil de aluno ou responsável > Nome
  ##
  def load_curriculum_unit_data
    curriculum_units = CurriculumUnit.find_default_by_user_id(current_user.id)

    # re-ordena as uc de acordo com o resultado dos tipos de perfil e o nome
    curriculum_units = curriculum_units.sort_by{ |curriculum_unit|
      curriculum_unit[:name] # a verificação do nome vem primeiro para ser sobreposta pela de maior prioridade
      # array com o resultado da comparação de bit entre o tipo do perfil do usuário em cada uc e o de responsável/aluno
      profile_types = Allocation.where(allocation_tag_id: AllocationTag.find(curriculum_unit[:allocation_tag_id]).related, user_id: current_user.id).compact.map(&:profile).map(&:types).uniq
      profile_types = profile_types.collect{|types| ((types & Profile_Type_Class_Responsible) != 0 or (types & Profile_Type_Student) != 0)}
      profile_types.include?(true) ? 0 : 1
    }

    # re-ordena as uc de acordo com a maior quantidade de acessos nas últimas três semanas
    curriculum_units = curriculum_units.sort_by { |curriculum_unit|
      -(Log.count(:id, conditions: {log_type: 3, user_id: current_user.id, curriculum_unit_id: curriculum_unit["id"], created_at: 3.week.ago..Time.now}))
    }

    return curriculum_units.uniq
  end

end
