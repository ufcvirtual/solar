class Webconference < ActiveRecord::Base
  GROUP_PERMISSION, OFFER_PERMISSION, CURRICULUM_UNIT_PERMISSION = true, true, true

  belongs_to :moderator, class_name: "User", foreign_key: :user_id

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags

  attr_accessible :description, :duration, :initial_time, :title

  validates :title, :initial_time, :duration, presence: true
  validates :title, :description, length: {maximum: 255}

  def can_access?
    Time.now.between?(initial_time, initial_time+duration.minutes)
  end

  def link_to_join(user)
    if can_access?
      ActionController::Base.helpers.link_to title,
        if user.id == moderator.id
          "http://www.bbb.com/link/moderador"
        else
          "http://www.bbb.com/link/normal"
        end, target: "_blank"
    else
      title
    end
  end

  def self.all_by_allocation_tags(allocation_tags_ids)
    joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: allocation_tags_ids}).order("initial_time, title")
  end
end
