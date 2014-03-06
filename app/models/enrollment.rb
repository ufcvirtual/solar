class Enrollment < ActiveRecord::Base

  ## Listagem de turmas
  # - Se type == enroll
  #   - listar turmas que usuário está matriculado
  # - Se type == all (ou outro valor)
  #   - listar turmas para usuario pedir matricula
  #     -- listar todas as turmas que podem receber matricula (olhar periodo de matricula na oferta)
  #     -- quando matriculado em uma turma, as outras turmas dessa mesma oferta deixam de ser listadas
  def self.enrollments_of_user(user, profile, type, offer_category = nil, curriculum_unit_id = nil)
    offer_category     = ((offer_category.nil? or offer_category.empty?) ? nil : offer_category.to_i)
    curriculum_unit_id = ((curriculum_unit_id.nil? or curriculum_unit_id.empty?) ? nil : curriculum_unit_id.to_i)

    query = []
    query << "curriculum_units.curriculum_unit_type_id = #{offer_category}" unless offer_category.nil?
    query << "curriculum_units.id = #{curriculum_unit_id}" unless curriculum_unit_id.nil?

    groups = Offer.joins(:curriculum_unit).where(query.join(" AND ")).map(&:groups).flatten.uniq.compact # todas as turmas que atendem os requisitos da busca

    if type == "enroll"
      (groups & user.groups(profile, Allocation_Activated)).uniq
    else
      current_groups = Offer.joins(curriculum_unit: :curriculum_unit_type).where(curriculum_unit_types: {allows_enrollment: true}).currents.map(&:groups).flatten.uniq.compact
      groups         = (groups & current_groups) # todas as turmas da busca que estão em ofertas ativas

      can_enroll  = groups.map {|group| 
        group if (group.offer.enrollment_start_date.to_date..(group.offer.enrollment_end_date.try(:to_date) || group.offer.end_date.to_date)).include?(Date.today)
      } # verifica período de matrícula

      user_groups = user.groups(profile, nil, curriculum_unit_id, offer_category)
      (can_enroll + user_groups).compact.uniq
    end
  end

end
