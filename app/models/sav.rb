class Sav < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :group

  validates :sav_id, :start_date, :end_date, presence: true
  validates :sav_id, uniqueness: { scope: :group_id }

  validate :end_after_start
 
  def end_after_start
    errors.add(:end_date, "deve ser depois do início") unless end_date >= start_date
  end

  def self.current_savs(group_id)
    Sav.where("group_id = ? OR group_id IS NULL", group_id).where("? BETWEEN start_date AND end_date", Date.today).pluck(:sav_id)
  end

end
