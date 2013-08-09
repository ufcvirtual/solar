class Enrollment < ActiveRecord::Base

  def self.enrollments_of_user(user, profile, offer_category = nil, curriculum_unit_id = nil)
    query = []
    query << "curriculum_unit_type_id = #{offer_category}" unless offer_category.nil? or offer_category.empty?
    query << "curriculum_units.id = #{curriculum_unit_id}" unless curriculum_unit_id.nil? or curriculum_unit_id.empty?

    groups = Group.joins(offer: [:semester, curriculum_unit: :curriculum_unit_type]).where(query.join(" AND "))
    (groups & user.groups(profile)).uniq
  end

  ## - listar turmas para usuario pedir matricula
  ##   -- listar todas as turmas que podem receber matricula (olhar periodo de matricula na oferta)
  ##   -- quando matriculado em uma turma, as outras turmas dessa mesma oferta deixam de ser listadas
  def self.all_enrollments_by_user(user, profile, offer_category = nil, curriculum_unit_id = nil)
    query = []
    query << "curriculum_unit_type_id = #{offer_category}" unless offer_category.nil? or offer_category.empty?
    query << "curriculum_units.id = #{curriculum_unit_id}" unless curriculum_unit_id.nil? or curriculum_unit_id.empty?

    # todas as turmas em que posso pedir matricula
    can_enroll = Group.joins(offer: [:semester, curriculum_unit: :curriculum_unit_type]).where(curriculum_unit_types: {allows_enrollment: true}).where(query.join(" AND "))
    can_enroll.select! { |group|
      (group.offer.enrollment_start_date.to_date..(group.offer.enrollment_end_date.try(:to_date) || group.offer.end_date.to_date)).include?(Date.today)
    }

    (can_enroll + user.groups(profile, true)).uniq
  end

end
