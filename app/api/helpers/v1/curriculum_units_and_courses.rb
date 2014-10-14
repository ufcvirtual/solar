module Helpers::V1::CurriculumUnitsAndCourses

  def verify_or_create_curriculum_unit(code, name, working_hours, credits, type = 2)
    uc = CurriculumUnit.where(code: code.slice(0..9)).first_or_initialize

    uc.attributes = {name: name.slice(0..119), working_hours: working_hours, credits: credits, curriculum_unit_type: (CurriculumUnitType.find(type) || CurriculumUnitType.find(2))}
    uc.attributes = {resume: name, objectives: name, syllabus: name} if uc.new_record?

    uc.save!

    uc
  end

  def course_params(params)
  	ActionController::Parameters.new(params).except("route_info").permit("name", "code")
  end

  def curriculum_unit_params(params, attributes = false)
  	attributes = (attributes ? {resume: params[:name], syllabus: params[:name], objectives: params[:name]} : {})
  	attributes.merge!(params.except("route_info"))
  end
  
end