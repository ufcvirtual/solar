class Semester < ActiveRecord::Base
  has_many :offers

  belongs_to :offer_schedule, class_name: "Schedule", foreign_key: "offer_schedule_id"
  belongs_to :enrollment_schedule, class_name: "Schedule", foreign_key: "enrollment_schedule_id"

  validates :name, :offer_schedule, :enrollment_schedule, presence: true

  attr_accessible :name, :offer_schedule_id, :enrollment_schedule_id
end
