class Menu < ActiveRecord::Base

  belongs_to :resource

  # auto-relacionamento
  has_many :children, class_name: 'Menu', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'Menu'

  # outros relacionamentos
  has_many :permissions_menus
  has_many :menus_contexts
  has_many :contexts, through: :menus_contexts

end
