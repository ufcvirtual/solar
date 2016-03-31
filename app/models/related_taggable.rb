class RelatedTaggable < ActiveRecord::Base

  belongs_to :group
  belongs_to :offer
  belongs_to :semester
  belongs_to :course
  belongs_to :curriculum_unit
  belongs_to :curriculum_unit_type
  belongs_to :schedule, class_name: 'Schedule', foreign_key: 'offer_schedule_id'
  has_many :digital_class_directories

  def at_ids(options = { lower: true, upper: true, name: nil })
    if options[:name]
      ids = []
      ids << group_at_id                if (options[:lower] || options[:name] == 'group')
      ids << offer_at_id                if (options[:lower] && options[:name] != 'group') || (options[:upper] && options[:name] == 'group') || options[:name] == 'offer'
      ids << curriculum_unit_at_id      if (options[:lower] && !['group', 'offer'].include?(options[:name])) || (options[:upper] && ['group', 'offer'].include?(options[:name])) || options[:name] == 'curriculum_unit'
      ids << course_at_id               if (options[:lower] && !['group', 'offer'].include?(options[:name])) || (options[:upper] && ['group', 'offer'].include?(options[:name])) || options[:name] == 'course'
      ids << curriculum_unit_type_at_id if options[:upper] || options[:name] == 'curriculum_unit_type'
      ids.compact
    else
      [group_at_id, offer_at_id, course_at_id, curriculum_unit_at_id, curriculum_unit_type_at_id].compact
    end
  end

  ## ferramenta academica: group, offer, course, uc, type
  def self.related(obj, options = { lower: true, upper: true, name: nil })
    rel = if obj.is_a?(Hash)
            where(obj)
          else
            name   = obj.class == AllocationTag ? obj.refer_to    : obj.class.to_s.underscore
            column = obj.class == AllocationTag ? "#{name}_at_id" : "#{name}_id"
            where("#{column} = ?", obj.id)
          end

    result = rel.map { |r| r.at_ids(options.merge!(name: name || options[:name] || r.at_refer_to)) }
    result.flatten.compact.uniq
  end

  def at_refer_to
    case
    when !group_at_id.nil?                then 'group'
    when !offer_at_id.nil?                then 'offer'
    when !curriculum_unit_at_id.nil?      then 'curriculum_unit'
    when !course_at_id.nil?               then 'course'
    when !curriculum_unit_type_at_id.nil? then 'curriculum_unit_type'
    end
  end

  def info
    { group: group.code, semester: offer.semester.name, discipline: curriculum_unit.code_name, course: course.code_name, curriculum_unit_type: curriculum_unit_type.description, curriculum_unit: curriculum_unit.code_name }
  end

  def self.related_from_array_ats(array_of_ats, options = {})
    options.reverse_merge!(lower: true, upper: true) if (options == {})

    return [] if array_of_ats.empty?

    unless options[:upper] && options[:lower]
      if options[:lower]
        RelatedTaggable.joins('JOIN allocation_tags ON ((allocation_tags.group_id IS NOT NULL AND allocation_tags.group_id = related_taggables.group_id) OR 
          (allocation_tags.curriculum_unit_id IS NOT NULL AND allocation_tags.curriculum_unit_id = related_taggables.curriculum_unit_id) OR (allocation_tags.offer_id IS NOT NULL AND allocation_tags.offer_id = related_taggables.offer_id) OR
          (allocation_tags.curriculum_unit_type_id IS NOT NULL AND allocation_tags.curriculum_unit_type_id = related_taggables.curriculum_unit_type_id) OR (allocation_tags.course_id IS NOT NULL AND allocation_tags.course_id = related_taggables.course_id))')
          .where(allocation_tags: { id: array_of_ats })
          .select('COALESCE(related_taggables.group_at_id, related_taggables.offer_at_id, related_taggables.curriculum_unit_at_id, related_taggables.course_at_id, related_taggables.curriculum_unit_type_at_id) AS at_id').map(&:at_id).map(&:to_i).uniq
      elsif options[:upper]
        allocation_tags = find_by_sql <<-SQL
          SELECT ARRAY[ats.at_g, ats.at_o, ats.at_c, ats.at_uc, ats.at_type] AS ats_ids
          FROM (
            SELECT array_agg(CASE WHEN allocation_tags.group_id IS NOT NULL THEN related_taggables.group_at_id ELSE 0 END) AS at_g, array_agg(CASE WHEN allocation_tags.offer_id IS NOT NULL OR allocation_tags.group_id IS NOT NULL THEN related_taggables.offer_at_id ELSE 0 END) AS at_o, array_agg(CASE WHEN allocation_tags.course_id IS NOT NULL OR allocation_tags.offer_id IS NOT NULL OR allocation_tags.group_id IS NOT NULL THEN related_taggables.course_at_id ELSE 0 END) AS at_c, array_agg(CASE WHEN allocation_tags.curriculum_unit_id IS NOT NULL OR allocation_tags.offer_id IS NOT NULL OR allocation_tags.group_id IS NOT NULL THEN related_taggables.curriculum_unit_at_id ELSE 0 END) AS at_uc, array_agg(CASE WHEN allocation_tags.curriculum_unit_type_id IS NOT NULL OR allocation_tags.curriculum_unit_id IS NOT NULL OR allocation_tags.offer_id IS NOT NULL OR allocation_tags.group_id IS NOT NULL THEN related_taggables.curriculum_unit_type_at_id ELSE 0 END) AS at_type
              FROM related_taggables
              JOIN allocation_tags ON ((allocation_tags.group_id IS NOT NULL AND allocation_tags.group_id =   related_taggables.group_id) OR (allocation_tags.curriculum_unit_id IS NOT NULL AND allocation_tags.curriculum_unit_id = related_taggables.curriculum_unit_id) OR (allocation_tags.offer_id IS NOT NULL AND allocation_tags.offer_id = related_taggables.offer_id) or (allocation_tags.curriculum_unit_type_id IS NOT NULL AND allocation_tags.curriculum_unit_type_id = related_taggables.curriculum_unit_type_id) OR (allocation_tags.course_id IS NOT NULL AND allocation_tags.course_id = related_taggables.course_id))
              WHERE(allocation_tags.id IN (#{array_of_ats.join(',')}))
            ) as ats
            GROUP BY ats_ids;
        SQL
        allocation_tags.first['ats_ids'].delete('{}NULL').split(',').map(&:to_i).delete_if { |at| at == 0 }.uniq
      end
    else

      allocation_tags = find_by_sql <<-SQL
        SELECT ARRAY[ats.at_g, ats.at_o, ats.at_c, ats.at_uc, ats.at_type] AS ats_ids
        FROM (
          SELECT array_agg(related_taggables.group_at_id) AS at_g, array_agg(related_taggables.offer_at_id) AS at_o, array_agg(related_taggables.curriculum_unit_at_id) AS at_c, array_agg(related_taggables.course_at_id) AS at_uc, array_agg(related_taggables.curriculum_unit_type_at_id) as at_type
          FROM related_taggables
          JOIN allocation_tags ON ((allocation_tags.group_id IS NOT NULL AND allocation_tags.group_id = related_taggables.group_id) OR (allocation_tags.curriculum_unit_id IS NOT NULL AND allocation_tags.curriculum_unit_id = related_taggables.curriculum_unit_id) OR (allocation_tags.offer_id IS NOT NULL AND allocation_tags.offer_id = related_taggables.offer_id) OR (allocation_tags.curriculum_unit_type_id IS NOT NULL AND allocation_tags.curriculum_unit_type_id = related_taggables.curriculum_unit_type_id) OR (allocation_tags.course_id IS NOT NULL AND allocation_tags.course_id = related_taggables.course_id))
          WHERE(allocation_tags.id IN (#{array_of_ats.join(',')}))
        ) as ats
        GROUP BY ats_ids;
      SQL
 
      allocation_tags.first['ats_ids'].delete('{}NULL').split(',').map(&:to_i).delete_if { |at| at == 0 }.uniq
    end
  end
end
