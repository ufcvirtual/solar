class Sav < ActiveRecord::Base

  belongs_to :allocation_tag
  belongs_to :profile

  validates :questionnaire_id, :start_date, :end_date, presence: true
  validates :questionnaire_id, uniqueness: { scope: [:allocation_tag_id, :profile_id] }

  validate :end_after_start

  def end_after_start
    errors.add(:end_date, "deve ser depois do início") unless end_date >= start_date
  end

  def self.current_savs(allocation_tags_ids)
    Sav.where("allocation_tag_id IN (?) OR allocation_tag_id IS NULL", allocation_tags_ids).where("? BETWEEN start_date AND end_date", Date.today)
  end

end
