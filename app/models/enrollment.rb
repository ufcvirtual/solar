class Enrollment < ActiveRecord::Base

  ## Listagem de turmas
  # - Se type == enroll
  #   - listar turmas que usuário está matriculado
  # - Se type == all
  #   - listar turmas para usuario pedir matricula
  #     -- listar todas as turmas que podem receber matricula (olhar periodo de matricula na oferta)
  #     -- quando matriculado em uma turma, as outras turmas dessa mesma oferta deixam de ser listadas

  ## offers, user, enroll_type, uc_type_id, _uc_id
  def self.enrollments_of_user(args = {})
    query = []
    query << "curriculum_units.curriculum_unit_type_id = :uc_type_id" unless args[:uc_type_id].blank?
    query << "curriculum_units.id = :uc_id" unless args[:uc_id].blank?

    profile = Profile.student_profile

    result = if args[:enroll_type] == 'enroll'
      args[:user].groups(profile, Allocation_Activated)
    else
      offers = args[:offers].where(query.join(' AND '), uc_type_id: args[:uc_type_id], uc_id: args[:uc_id]).map(&:id)
      groups = Group.where(offer_id: offers) # turmas das ofertas correntes

      can_enroll  = groups.map {|group|
        group if (group.offer.enrollment_start_date.to_date..(group.offer.enrollment_end_date.try(:to_date) || group.offer.end_date.to_date)).include?(Date.today)
      } # verifica período de matrícula

      [can_enroll, args[:user].groups(profile, nil, args[:uc_id], args[:uc_type_id])].flatten.compact.uniq
    end
  end

end
