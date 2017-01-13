class QuestionItem < ActiveRecord::Base

  belongs_to :question

  has_many :exam_responses_question_items
  has_many :exam_responses, through: :exam_responses_question_items

  validates_attachment_size :item_image, less_than: 2.megabyte, message: ''
  validates_attachment_content_type :item_image, content_type: /^image\/(jpg|jpeg|pjpeg|png|x-png|gif)$/, message: I18n.t('questions.error.wrong_type')

  validates :description, presence: true

  validates :img_alt, presence: true, if: '(!item_image_file_name.blank? && img_alt.blank?)'

  has_attached_file :item_image,
                    styles: { small: '120x120'},
                    path: ':rails_root/media/questions/items/:id_:basename.:extension',
                    url: '/media/questions/items/:id_:basename.:extension'

  validates_attachment_size :item_audio, less_than: 10.megabyte, message: ''
  validates_attachment_content_type :item_audio, content_type: /^audio\/(mpeg|x-mpeg|mp3|x-mp3|mpeg3|x-mpeg3|mpg|x-mpg|x-mpegaudio)$/, message: I18n.t('questions.error.wrong_type')

  has_attached_file :item_audio,
                    path: ':rails_root/media/questions/items/:id_:basename.:extension',
                    url: '/media/questions/items/:id_:basename.:extension'

  before_destroy :can_destroy?

  def can_destroy?
    raise 'in_use' if exam_responses.any?
  end
  
end
