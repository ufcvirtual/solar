class Course < ActiveRecord::Base

  has_one :allocation_tag
  has_many :offers
  has_many :groups, :through => :offers, :uniq => true

  include Taggable
  
  def has_any_lower_association?
      self.offers.count > 0
  end

  def lower_associated_objects
    offers
  end
  
end
