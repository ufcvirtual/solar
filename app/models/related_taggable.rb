class RelatedTaggable < ActiveRecord::Base

  belongs_to :group
  belongs_to :offer
  belongs_to :semester
  belongs_to :course
  belongs_to :curriculum_unit
  belongs_to :curriculum_unit_type
  belongs_to :schedule, class_name: "Schedule", foreign_key: "offer_schedule_id"

  def at_ids(options={lower: true, upper: true, name: nil})
    unless options[:name]
      [group_at_id, offer_at_id, course_at_id, curriculum_unit_at_id, curriculum_unit_type_at_id].compact
    else
      ids = []
      ids << group_at_id                if (options[:lower] or options[:name] == "group")
      ids << offer_at_id                if (options[:lower] and options[:name] != "group") or (options[:upper] and options[:name] == "group") or options[:name] == "offer"
      ids << curriculum_unit_at_id      if (options[:lower] and not(["group", "offer"].include?(options[:name]))) or (options[:upper] and ["group", "offer"].include?(options[:name])) or options[:name] == "curriculum_unit"
      ids << course_at_id               if (options[:lower] and not(["group", "offer"].include?(options[:name]))) or (options[:upper] and ["group", "offer"].include?(options[:name])) or options[:name] == "course"
      ids << curriculum_unit_type_at_id if (options[:upper] or options[:name] == "curriculum_unit_type")
      ids.compact
    end
  end

  ## ferramenta academica: group, offer, course, uc, type  
  def self.related(obj, options={lower: true, upper: true, name: nil})
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
      when not(group_at_id.nil?); "group"
      when not(offer_at_id.nil?); "offer"
      when not(curriculum_unit_at_id.nil?); "curriculum_unit"
      when not(course_at_id.nil?); "course"
      when not(curriculum_unit_type_at_id.nil?); "curriculum_unit_type"
    end
  end

  def self.related_from_array_ats(array_of_ats, options={})
    options.reverse_merge!({lower: true, upper: true}) if (options == {})

    return [] if array_of_ats.empty?

    unless options[:upper] and options[:lower]
      if options[:lower]
        RelatedTaggable.joins("JOIN allocation_tags ON ((allocation_tags.group_id IS NOT NULL AND allocation_tags.group_id = related_taggables.group_id) OR 
          (allocation_tags.curriculum_unit_id IS NOT NULL AND allocation_tags.curriculum_unit_id = related_taggables.curriculum_unit_id) OR (allocation_tags.offer_id IS NOT NULL AND allocation_tags.offer_id = related_taggables.offer_id) OR
          (allocation_tags.curriculum_unit_type_id IS NOT NULL AND allocation_tags.curriculum_unit_type_id = related_taggables.curriculum_unit_type_id) OR (allocation_tags.course_id IS NOT NULL AND allocation_tags.course_id = related_taggables.course_id))")
          .where(allocation_tags: {id: array_of_ats})
          .select("COALESCE(related_taggables.group_at_id, related_taggables.offer_at_id, related_taggables.curriculum_unit_at_id, related_taggables.course_at_id, related_taggables.curriculum_unit_type_at_id) AS at_id").map(&:at_id).map(&:to_i)
      elsif options[:upper]
        allocation_tags = find_by_sql <<-SQL
          SELECT ARRAY[ats.at_g, ats.at_o, ats.at_c, ats.at_uc, ats.at_type] AS ats_ids
          FROM (
            SELECT array_agg(CASE WHEN allocation_tags.group_id IS NOT NULL THEN related_taggables.group_at_id ELSE 0 END) AS at_g, array_agg(CASE WHEN allocation_tags.offer_id IS NOT NULL OR allocation_tags.group_id IS NOT NULL THEN related_taggables.offer_at_id ELSE 0 END) AS at_o, array_agg(CASE WHEN allocation_tags.course_id IS NOT NULL OR allocation_tags.offer_id IS NOT NULL OR allocation_tags.group_id IS NOT NULL THEN related_taggables.course_at_id ELSE 0 END) AS at_c, array_agg(CASE WHEN allocation_tags.curriculum_unit_id IS NOT NULL OR allocation_tags.offer_id IS NOT NULL OR allocation_tags.group_id IS NOT NULL THEN related_taggables.curriculum_unit_at_id ELSE 0 END) AS at_uc, array_agg(CASE WHEN allocation_tags.curriculum_unit_type_id IS NOT NULL OR allocation_tags.curriculum_unit_id IS NOT NULL OR allocation_tags.offer_id IS NOT NULL OR allocation_tags.group_id IS NOT NULL THEN related_taggables.curriculum_unit_type_at_id ELSE 0 END) AS at_type
              FROM related_taggables
              JOIN allocation_tags ON ((allocation_tags.group_id IS NOT NULL AND allocation_tags.group_id =   related_taggables.group_id) OR (allocation_tags.curriculum_unit_id IS NOT NULL AND allocation_tags.curriculum_unit_id = related_taggables.curriculum_unit_id) OR (allocation_tags.offer_id IS NOT NULL AND allocation_tags.offer_id = related_taggables.offer_id) or (allocation_tags.curriculum_unit_type_id IS NOT NULL AND allocation_tags.curriculum_unit_type_id = related_taggables.curriculum_unit_type_id) OR (allocation_tags.course_id IS NOT NULL AND allocation_tags.course_id = related_taggables.course_id))
              WHERE(allocation_tags.id IN (#{array_of_ats.join(",")}))
            ) as ats
            GROUP BY ats_ids;
        SQL
        allocation_tags.first["ats_ids"].delete('{}NULL').split(",").map(&:to_i).delete_if{|at| at==0}
      end
    else
        allocation_tags = find_by_sql <<-SQL
          SELECT ARRAY[ats.at_g, ats.at_o, ats.at_c, ats.at_uc, ats.at_type] AS ats_ids
          FROM (
            SELECT array_agg(related_taggables.group_at_id) AS at_g, array_agg(related_taggables.offer_at_id) AS at_o, array_agg(related_taggables.curriculum_unit_at_id) AS at_c, array_agg(related_taggables.course_at_id) AS at_uc, array_agg(related_taggables.curriculum_unit_type_at_id) as at_type
            FROM related_taggables
            JOIN allocation_tags ON ((allocation_tags.group_id IS NOT NULL AND allocation_tags.group_id = related_taggables.group_id) OR (allocation_tags.curriculum_unit_id IS NOT NULL AND allocation_tags.curriculum_unit_id = related_taggables.curriculum_unit_id) OR (allocation_tags.offer_id IS NOT NULL AND allocation_tags.offer_id = related_taggables.offer_id) OR (allocation_tags.curriculum_unit_type_id IS NOT NULL AND allocation_tags.curriculum_unit_type_id = related_taggables.curriculum_unit_type_id) OR (allocation_tags.course_id IS NOT NULL AND allocation_tags.course_id = related_taggables.course_id))
            WHERE(allocation_tags.id IN (#{array_of_ats.join(",")}))
          ) as ats
          GROUP BY ats_ids;
        SQL

        allocation_tags.first["ats_ids"].delete('{}NULL').split(",").map(&:to_i).delete_if{|at| at==0}
    end
  end
end
