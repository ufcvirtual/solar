class Author < ActiveRecord::Base

  belongs_to :bibliography

  validates :name, presence: true

end
