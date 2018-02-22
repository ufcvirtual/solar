class QuestionImage < ActiveRecord::Base
  belongs_to :question

  has_attached_file :image,
          styles: { small: '150x150>', medium: '250x250>', large: '350x350>' },
          path: ':rails_root/media/questions/images/:id_:basename_:style.:extension',
          url: '/media/questions/images/:id_:basename_:style.:extension'

  validates :image, presence: true

  validates :img_alt, presence: true, if: 'img_alt.blank?'
  validates :legend, length: { maximum: 100 }

  validates_attachment_size :image, less_than: 2.megabyte
  validates_attachment_content_type :image, content_type: /^image\/(jpg|jpeg|pjpeg|png|x-png|gif)$/ , message: I18n.t('questions.error.wrong_type')
  validates_attachment_content_type_in_black_list :image

  before_save :replace_image_name



  def self.list(question_id)
    QuestionImage.where(question_id: question_id)
      .select('DISTINCT question_images.id, question_images.legend, question_images.image_file_name, question_images.image_content_type, question_images.image_file_size, question_images.image_updated_at, question_images.img_alt')
  end

  Paperclip.interpolates :normalized_image_file_name do |attachment, style|
    attachment.instance.normalized_image_file_name
  end

  def normalized_image_file_name
    image_name= image_file_name.split('.')
    extension = image_name.last
    image_name.pop
    image_name_2 = image_name.to_sentence(two_words_connector: '_')
   "#{image_name_2.gsub( /[^a-zA-Z0-9_\.]/, '_')}.#{extension}"
  end

  private
    def replace_image_name
      self.image_file_name = normalized_image_file_name
    end
end
