class Group < ActiveRecord::Base

  has_one :allocation_tag
  belongs_to :offer

  def code_semester
    "#{code} - #{semester}"
  end
  
end
