class Context < ActiveRecord::Base
  has_and_belongs_to_many :menus
end
