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
    AllocationTag.curriculum_unit_type(allocation_tag)
  end

  def semester(allocation_tag)
    AllocationTag.semester_info(allocation_tag)
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