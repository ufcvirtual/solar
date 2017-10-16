class QuestionText < ActiveRecord::Base

  has_many :questions	

  validates :text, presence: true
end
