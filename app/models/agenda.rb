class Agenda < ActiveRecord::Base
  has_many :agenda_types

  belongs_to :allocation_tag
end
