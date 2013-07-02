class Semester < ActiveRecord::Base
  has_many :offers

  belongs_to :offer_schedule, class_name: "Schedule", foreign_key: "offer_schedule_id"
  belongs_to :enrollment_schedule, class_name: "Schedule", foreign_key: "enrollment_schedule_id"

  validates :name, presence: true

  accepts_nested_attributes_for :offer_schedule
  accepts_nested_attributes_for :enrollment_schedule

  attr_accessible :name, :offer_schedule_attributes, :enrollment_schedule_attributes
end
