class Group < ActiveRecord::Base

  has_one :allocation_tag
  belongs_to :offer
  has_many :logs

  def code_semester
    "#{code} - #{semester}"
  end
  
end
