class Author < ActiveRecord::Base
  belongs_to :bibliography

  validates :name, presence: true

  attr_accessible :name
end
