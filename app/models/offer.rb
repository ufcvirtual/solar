class Offer < ActiveRecord::Base

  has_many :groups

  has_one :enrollment

  belongs_to :course
  belongs_to :curriculum_unit

end