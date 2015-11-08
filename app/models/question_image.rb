class QuestionImage < ActiveRecord::Base

  belongs_to :question

  validates :image, :img_alt, presence: true
  validates_attachment_size :image, less_than: 2.megabyte, message: 'too big'
  validates_attachment_content_type_in_black_list :image

  has_attached_file :image,
                    path: ':rails_root/media/questions/images/:id_:basename.:extension',
                    url: '/media/questions/images/:id_:basename.:extension'
end
