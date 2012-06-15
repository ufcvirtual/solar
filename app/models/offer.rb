class Offer < ActiveRecord::Base
  belongs_to :course
  belongs_to :curriculum_unit

  has_one :allocation_tag
  has_one :enrollment

  has_many :groups
  has_many :assignments, :through => :allocation_tag
end