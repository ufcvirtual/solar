class PersonalConfiguration < ActiveRecord::Base

  def self.default_portlet_configuration
    "1&2|3&4|5"
  end
  
end
