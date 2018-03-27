class PersonalConfiguration < ActiveRecord::Base

  belongs_to :user
  before_save :downcase_theme

  validates :user_id, presence: true, uniqueness: true

  def downcase_theme
    self.theme = theme.downcase
  end
end
