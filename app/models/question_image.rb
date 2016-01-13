class QuestionImage < ActiveRecord::Base
  belongs_to :question

  validates :image, presence: true

  validate :alt, if: 'img_alt.blank?'

  validates_attachment_size :image, less_than: 2.megabyte, message: 'too big'
  validates_attachment_content_type :image, content_type: /^image\/(jpg|jpeg|pjpeg|png|x-png|gif)$/, message: 'file type is not allowed (only jpeg/png/gif images)'
  validates_attachment_content_type_in_black_list :image

  has_attached_file :image,
          path: ':rails_root/media/questions/images/:id_:basename.:extension',
          url: '/media/questions/images/:id_:basename.:extension'

  def alt
    errors.add(:base, I18n.t('questions.error.alt'))
  end
end
