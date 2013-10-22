class ScheduleEvent < ActiveRecord::Base
  belongs_to :schedule
  belongs_to :allocation_tag

  include Event
end
