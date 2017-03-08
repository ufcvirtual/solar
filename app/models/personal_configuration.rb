class PersonalConfiguration < ActiveRecord::Base

  belongs_to :user
  before_save :downcase_theme
  
  def downcase_theme
    self.theme = theme.downcase
  end
end
