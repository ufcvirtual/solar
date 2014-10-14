module Helpers::V1::GroupsH

  def get_group(curriculum_unit_code, course_code, code, period, year)
    semester = (period.blank? ? year : "#{year}.#{period}")
    Group.joins(offer: :semester).where(code: code, 
      offers: {curriculum_unit_id: CurriculumUnit.where(code: curriculum_unit_code).first, 
               course_id: Course.where(code: course_code).first},
      semesters: {name: semester}).first
  end

  def get_offer_group(offer, group_code)
    offer.groups.where(code: group_code).first
  end

  def verify_or_create_group(params)
    group = Group.where(group_params(params)).first_or_initialize
    group.status = true
    group.save!
    group
  end

  def group_params(params)
    ActionController::Parameters.new(params).except("route_info").permit("code", "offer_id")
  end

end