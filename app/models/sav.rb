class Sav < ActiveRecord::Base

  belongs_to :allocation_tag
  belongs_to :profile

  validates :questionnaire_id, presence: true
  validates :questionnaire_id, uniqueness: { scope: [:allocation_tag_id, :semester_id, :profile_id] }

  validates :percent, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, unless: Proc.new { |a| a.percent.blank? || a.percent == 0 }

  validate :end_after_start, unless: Proc.new { |a| a.start_date.blank? || a.end_date.blank? }

  before_save :define_percent, unless: Proc.new { |a| a.percent.blank? }

  def define_percent
    self.percent = nil           if percent.blank? || percent == 1 || percent == 100 || percent == 0
    self.percent = (percent/100) if !percent.blank? && percent > 1
  end

  def end_after_start
    errors.add(:end_date, "deve ser depois do início") unless end_date >= start_date
  end

  def self.current_savs(params = {allocation_tags_ids: [], group_id: nil})
    joins("JOIN related_taggables ON (related_taggables.group_at_id = allocation_tag_id OR related_taggables.offer_at_id = allocation_tag_id OR related_taggables.course_at_id = allocation_tag_id OR related_taggables.curriculum_unit_at_id = allocation_tag_id OR related_taggables.curriculum_unit_type_at_id = allocation_tag_id)")
    .joins("JOIN groups    ON related_taggables.group_id = groups.id AND groups.id = #{params[:group_id]}")
    .joins("JOIN offers    ON offers.id                  = groups.offer_id")
    .joins("JOIN semesters ON semesters.id               = offers.semester_id")
    .joins("JOIN schedules ON schedules.id               = COALESCE(offers.offer_schedule_id, semesters.offer_schedule_id)")
    .select("savs.semester_id, allocation_tag_id, questionnaire_id, profile_id")
    .where("(
              (
                allocation_tag_id IN (#{params[:allocation_tags_ids].join(",")}) 
                AND (savs.semester_id = semesters.id OR savs.semester_id IS NULL)
              ) OR allocation_tag_id IS NULL 
            ) AND 
              now()::date BETWEEN COALESCE(
                  savs.start_date, 
                  (schedules.start_date + ((percent*DATE_PART('day', schedules.end_date::timestamp - schedules.start_date::timestamp)) || ' day')::interval)::date,
                  schedules.start_date
              ) AND COALESCE(savs.end_date, schedules.end_date)
    "
    )
  end

end
