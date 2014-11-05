module V1::CurriculumUnitsAndCourses

  def verify_or_create_curriculum_unit(attributes)
    uc = CurriculumUnit.where(code: attributes[:code]).first_or_initialize
    uc.attributes = curriculum_unit_params(ActiveSupport::HashWithIndifferentAccess.new(uc.attributes.merge!(attributes)), true)
    uc.save!
    uc
  end

  def course_params(params)
  	ActionController::Parameters.new(params).except("route_info").permit("name", "code")
  end

  def curriculum_unit_params(params, attributes = false)
    name       = (params.has_key?(:name) ? params[:name] : params["name"])
  	attributes = (attributes ? {resume: name, syllabus: name, objectives: name} : {})
  	ActiveSupport::HashWithIndifferentAccess.new attributes.merge!(params.except("route_info", "update_if_exists").delete_if { |k,v| v.nil? })
  end
  
end