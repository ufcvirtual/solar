class DiscussionPost < ActiveRecord::Base
  has_many :children, :class_name => "DiscussionPost", :foreign_key => "father_id"
  has_many :discussion_post_files
  belongs_to :father, :class_name => "DiscussionPost"

  belongs_to :discussion
  belongs_to :user

  #Falta implementar as validações aqui!!

end
