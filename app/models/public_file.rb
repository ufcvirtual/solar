class PublicFile < ActiveRecord::Base

  belongs_to :user
  belongs_to :allocation_tag

  ################################
  # attachment files
  ################################

#  time_save = Time.now.strftime("%Y%m%d%H%M%S")

  has_attached_file :attachment,
    :path => ":rails_root/media/portfolio/public_area/:id_:basename.:extension",
    :url => "/media/portfolio/public_area/:id_:basename.:extension"

end
