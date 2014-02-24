class Webconference < ActiveRecord::Base
  GROUP_PERMISSION, OFFER_PERMISSION, CURRICULUM_UNIT_PERMISSION = true, true, true

  belongs_to :user

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags

  attr_accessible :description, :duration, :initial_time, :title

  validates :title, :initial_time, :duration, presence: true

  def moderator
    user
  end

end
