class QuestionImage < ActiveRecord::Base
  belongs_to :question

  validates :image, presence: true

  validates :img_alt, presence: true, if: 'img_alt.blank?'
  validates :legend, length: { maximum: 100 }

  validates_attachment_size :image, less_than: 2.megabyte
  validates_attachment_content_type :image, content_type: /^image\/(jpg|jpeg|pjpeg|png|x-png|gif)$/
  validates_attachment_content_type_in_black_list :image

  has_attached_file :image,
          styles: { small: '150x150', medium: '220x220', large: '300x300' },
          path: ':rails_root/media/questions/images/:id_:basename.:extension',
          url: '/media/questions/images/:id_:basename.:extension'

  def self.list(question_id)
    QuestionImage.where(question_id: question_id)
      .select('DISTINCT question_images.id, question_images.legend, question_images.image_file_name, question_images.image_content_type, question_images.image_file_size, question_images.image_updated_at, question_images.img_alt')
  end
end
