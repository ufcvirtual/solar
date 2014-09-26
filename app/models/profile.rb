class Profile < ActiveRecord::Base

  has_many :users, through: :allocations
  has_many :allocations, dependent: :restrict

  has_and_belongs_to_many :resources, join_table: "permissions_resources"

  validates :description, :name, presence: true
  validates :name, length: {maximum: 255}
  validates :description, length: {maximum: 500}

  attr_accessor :template

  def self.all_except_basic
    Profile.where("types <> ?", Profile_Type_Basic).order("name")
  end

  def has_type?(type)
    (self.types & type) == type
  end

  def self.student_profile
    find_by_types(Profile_Type_Student).id
  end

end
