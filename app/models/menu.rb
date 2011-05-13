class Menu < ActiveRecord::Base
  # auto-relacionamento
  has_many :children, :class_name => "Menu", :foreign_key => "father_id"
  belongs_to :father, :class_name => "Menu"
end
