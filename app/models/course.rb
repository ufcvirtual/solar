class Course < ActiveRecord::Base

  include Taggable

  has_many :offers
  has_many :groups, :through => :offers, :uniq => true
  has_many :curriculum_units, :through => :offers, :uniq => true

  def has_any_lower_association?
      self.offers.count > 0
  end

  def lower_associated_objects
    offers
  end

end
