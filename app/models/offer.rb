class Offer < ActiveRecord::Base
  belongs_to :course
  belongs_to :curriculum_unit

  has_one :allocation_tag
  has_one :enrollment

  has_many :groups
  has_many :assignments, :through => :allocation_tag

  attr_accessor :user_id

  def has_any_down_association?
      self.groups.count > 0
  end
end