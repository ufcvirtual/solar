class Portfolio < ActiveRecord::Base
  belongs_to :schedule
  set_table_name "assignments"

end
