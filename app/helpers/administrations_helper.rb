module AdministrationsHelper

  include AllocationsHelper

  def last_accessed(id)
    last_accessed = LogAccess.find_by_user_id(id)
    last_accessed.nil? ? " - " : l(last_accessed.created_at.to_date, format: :default).to_s 
  end

  def allocation_details(allocation_tag)
    AllocationTag.allocation_tag_details(allocation_tag)
  end

  def type(allocation_tag)
    return I18n.t("users.profiles.not_specified") if allocation_tag.nil?
    allocation_tag.curriculum_unit_type
  rescue
    ''
  end

  def semester(allocation_tag)
    return 'allocation_tag' if allocation_tag.nil?
    allocation_tag.semester_info
  rescue
    ''
  end

  def name_allocation_status(status)
    name_of(status, false)
  end

  def allocation_status
    status = status_hash(false)
  end

  def user_status
    { 0 => t(:blocked), 1 => t(:active) }
  end
end