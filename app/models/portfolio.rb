class Portfolio < ActiveRecord::Base

  set_table_name "assignments"
  belongs_to :schedule

end
