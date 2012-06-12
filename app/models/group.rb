class Group < ActiveRecord::Base

  has_one :allocation_tag
  belongs_to :offer
  has_many :logs
  has_one :curriculum_unit, :through => :offer
  has_one :course, :through => :offer
  has_many :users, :through => :allocation_tag

  def code_semester
    "#{code} - #{semester}"
  end

end
