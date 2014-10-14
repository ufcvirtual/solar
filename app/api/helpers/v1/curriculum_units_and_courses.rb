module Helpers::V1::CurriculumUnitsAndCourses

  def verify_or_create_curriculum_unit(attributes)
    uc = CurriculumUnit.where(code: attributes[:code]).first_or_initialize
    uc.attributes = curriculum_unit_params(uc.attributes.merge!(attributes), true)
    uc.save!
  end

  def course_params(params)
  	ActionController::Parameters.new(params).except("route_info").permit("name", "code")
  end

  def curriculum_unit_params(params, attributes = false)
  	attributes = (attributes ? {resume: params[:name], syllabus: params[:name], objectives: params[:name]} : {})
  	attributes.merge!(params.except("route_info"))
  end
  
end