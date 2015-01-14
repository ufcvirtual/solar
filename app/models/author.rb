class Author < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :bibliography

  validates :name, presence: true

end
