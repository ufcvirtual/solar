class RelatedTaggable < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :group
  belongs_to :offer
  belongs_to :semester
  belongs_to :course
  belongs_to :curriculum_unit
  belongs_to :curriculum_unit_type
  belongs_to :schedule

  def at_ids
    [group_at_id, offer_at_id, course_at_id, curriculum_unit_at_id, curriculum_unit_type_at_id].compact
  end

  ## class methods

  ## ferramenta academica: group, offer, course, uc, type
  def self.related(obj)
    rel = if obj.is_a?(Hash)
      where(obj)
    else
      column = obj.is_a?(AllocationTag) ? "#{obj.refer_to}_at_id" : "#{obj.class.to_s.underscore}_id"
      where("#{column} = ?", obj.id)
    end

    result = rel.map { |r| r.at_ids }
    result.flatten.compact.uniq
  end

end
