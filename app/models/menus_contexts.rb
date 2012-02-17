class MenusContexts < ActiveRecord::Base
  has_many :menus
  has_many :contexts
end
