class Course < ActiveRecord::Base

  has_one :allocation_tag
  has_many :offers
  has_many :groups, :through => :offers, :uniq => true

  def has_any_down_association?
      self.offers.count > 0
  end
  
end
