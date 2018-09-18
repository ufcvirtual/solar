module AdministrationsHelper

  include AllocationsHelper

  def last_accessed(id)
    last_accessed = LogAccess.find_by_user_id(id)
    last_accessed.nil? ? " - " : l(last_accessed.created_at.to_date, format: :default).to_s
  end

  def type(allocation_tag)
    allocation_tag.curriculum_unit_types
  rescue
    I18n.t("users.profiles.not_specified")
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

  def list_allocations_user(user_id, semester_id=nil)
    allocation_tags_ids = current_user.allocation_tags_ids_with_access_on(['allocations_user'], 'administrations', false, true) # if has nil, exists an allocation with allocation_tag_id nil
    query = allocation_tags_ids.include?(nil) ? '' : ['allocation_tag_id IN (?)', allocation_tags_ids]
    unless semester_id.blank?
      where = "related_taggables.semester_id=#{semester_id} OR rt_curric.semester_id=#{semester_id} OR rt_course.semester_id=#{semester_id} OR rt_cut.semester_id=#{semester_id} OR rt_off.semester_id=#{semester_id}"
    else
      where = "CURRENT_DATE BETWEEN sch_group.start_date AND sch_group.end_date OR CURRENT_DATE BETWEEN sch_curric.start_date AND sch_curric.end_date
              OR CURRENT_DATE BETWEEN sch_course.start_date AND sch_course.end_date OR CURRENT_DATE BETWEEN sch_cut.start_date AND sch_cut.end_date OR
              CURRENT_DATE BETWEEN sch_off.start_date AND sch_off.end_date"
    end
    #@allocations_user = User.find(params[:id]).allocations.joins(:profile).where('NOT cast(profiles.types & ? as boolean)', Profile_Type_Basic).where(query)
    allocations = Allocation.joins(:profile).where('NOT cast(profiles.types & ? as boolean) AND user_id = ?', Profile_Type_Basic, user_id).where(query)
    allocations = allocations.joins('LEFT JOIN allocation_tags ON allocations.allocation_tag_id = allocation_tags.id')
    .joins('LEFT JOIN related_taggables ON allocation_tags.group_id = related_taggables.group_id')
    .joins('LEFT JOIN courses ON related_taggables.course_id = courses.id')
    .joins('LEFT JOIN curriculum_unit_types ON related_taggables.curriculum_unit_type_id = curriculum_unit_types.id')
    .joins('LEFT JOIN curriculum_units ON related_taggables.curriculum_unit_id = curriculum_units.id')
    .joins('LEFT JOIN groups ON related_taggables.group_id = groups.id')
    .joins('LEFT JOIN semesters AS sem_group ON sem_group.id = related_taggables.semester_id')
    .joins('LEFT JOIN schedules AS sch_group ON sch_group.id = related_taggables.offer_schedule_id')
    .joins('LEFT JOIN related_taggables AS rt_curric ON allocation_tags.curriculum_unit_id = rt_curric.curriculum_unit_id')
    .joins('LEFT JOIN curriculum_unit_types AS curric_cut ON rt_curric.curriculum_unit_type_id = curric_cut.id')
    .joins('LEFT JOIN curriculum_units AS curric_curric ON rt_curric.curriculum_unit_id = curric_curric.id')
    .joins('LEFT JOIN schedules AS sch_curric ON sch_curric.id = rt_curric.offer_schedule_id')
    .joins('LEFT JOIN related_taggables AS rt_course ON allocation_tags.course_id = rt_course.course_id')
    .joins('LEFT JOIN courses AS c_course ON rt_course.course_id = c_course.id')
    .joins('LEFT JOIN schedules AS sch_course ON sch_course.id = rt_course.offer_schedule_id')
    .joins('LEFT JOIN related_taggables AS rt_cut ON allocation_tags.curriculum_unit_type_id = rt_cut.curriculum_unit_type_id')
    .joins('LEFT JOIN curriculum_unit_types AS cut_cut ON rt_cut.curriculum_unit_type_id = cut_cut.id')
    .joins('LEFT JOIN schedules AS sch_cut ON sch_cut.id = rt_cut.offer_schedule_id')
    .joins('LEFT JOIN related_taggables AS rt_off ON allocation_tags.offer_id = rt_off.offer_id')
    .joins('LEFT JOIN courses AS c_off ON rt_off.course_id = c_off.id')
    .joins('LEFT JOIN curriculum_unit_types AS off_cut ON rt_off.curriculum_unit_type_id = off_cut.id')
    .joins('LEFT JOIN curriculum_units AS off_curric ON rt_off.curriculum_unit_id = off_curric.id')
    .joins('LEFT JOIN semesters AS sem_off ON sem_off.id = rt_off.semester_id')
    .joins('LEFT JOIN schedules AS sch_off ON sch_off.id = rt_off.offer_schedule_id')
    .where(where)
    .select("DISTINCT allocations.id, allocations.user_id, allocations.profile_id, allocations.status, allocations.allocation_tag_id, allocations.updated_at,
            allocations.updated_by_user_id,  CONCAT(curriculum_unit_types.description, cut_cut.description, curric_cut.description, off_cut.description) AS description,
            concat_ws(' - ', CONCAT(courses.code, c_course.code, c_off.code), CONCAT(courses.name, c_course.name, c_off.name)) AS course_name, concat_ws(' - ', CONCAT(curriculum_units.code, curric_curric.code, off_curric.code),CONCAT(curriculum_units.name, curric_curric.name, off_curric.name)) AS curric_name,
            CONCAT(sem_group.name, sem_off.name) AS semester, CASE WHEN groups.name = groups.code THEN groups.name ELSE concat_ws(' - ', groups.name, groups.code) END AS group_code")
  end


end