class QuestionItem < ActiveRecord::Base

  belongs_to :question

  has_many :exam_responses_question_items
  has_many :exam_responses, through: :exam_responses_question_items

  validates_attachment_size :item_image, less_than: 2.megabyte, message: ''
  validates_attachment_content_type :item_image, content_type: /^image\/(jpg|jpeg|pjpeg|png|x-png|gif)$/, message: I18n.t('questions.error.wrong_type')

  validates :description, presence: true

  validates :img_alt, presence: true, if: '(!item_image_file_name.blank? && img_alt.blank?)'

  validates :audio_description, presence: true, if: '(!item_audio_file_name.blank?)'

  has_attached_file :item_image,
                    styles: { small: '120x120'},
                    path: ':rails_root/media/questions/items/:id_:basename.:extension',
                    url: '/media/questions/items/:id_:basename.:extension'

  validates_attachment_size :item_audio, less_than: 10.megabyte, message: ''
  validates_attachment_content_type :item_audio, content_type: /^audio\/(mpeg|x-mpeg|mp3|x-mp3|mpeg3|x-mpeg3|mpg|x-mpg|x-mpegaudio)$/, message: I18n.t('questions.error.wrong_type_audio')

  has_attached_file :item_audio,
                    path: ':rails_root/media/questions/items/:id_:normalized_item_audio_file_name',
                    url: '/media/questions/items/:id_:normalized_item_audio_file_name'

  before_destroy :can_destroy?

  after_create :replace_audio, if: '(!item_audio_file_name.blank?)'

  def can_destroy?
    raise 'in_use' if exam_responses.any?
  end

  Paperclip.interpolates :normalized_item_audio_file_name do |attachment, style|
    attachment.instance.normalized_item_audio_file_name
  end

  def normalized_item_audio_file_name
    audio_name= item_audio_file_name.split('.')
    extension = audio_name.last
    audio_name.pop
    audio_name_2 = audio_name.to_sentence(two_words_connector: '_')
   "#{audio_name_2.gsub( /[^a-zA-Z0-9_\.]/, '_')}.#{extension}"
  end

  private
  def replace_audio
    self.update_attributes(:item_audio_file_name => normalized_item_audio_file_name)
  end
  
end
