class QuestionAudio < ActiveRecord::Base
  belongs_to :question

  validates :audio, presence: true
  validates :audio_description, presence: true, if: 'description.blank?'
  validates :description, presence: true, if: 'audio_description.blank?'

  validates_attachment_size :audio, less_than: 10.megabyte, message: ''
  validates_attachment_content_type :audio, content_type: /^audio\/(mpeg|x-mpeg|mp3|x-mp3|mpeg3|x-mpeg3|mpg|x-mpg|x-mpegaudio)$/, message: I18n.t('questions.error.wrong_type_audio')

  has_attached_file :audio,
                    path: ':rails_root/media/questions/audios/:id_:normalized_audio_file_name',
                    url: '/media/questions/audios/:id_:normalized_audio_file_name'                 
  
  before_save :replace_audio
                    
  def self.list(question_id)
    QuestionAudio.where(question_id: question_id)
      .select('DISTINCT question_audios.id, question_audios.audio_file_name, question_audios.audio_content_type, question_audios.audio_file_size, question_audios.audio_updated_at, description, audio_description')
  end

  Paperclip.interpolates :normalized_audio_file_name do |attachment, style|
    attachment.instance.normalized_audio_file_name
  end

  def normalized_audio_file_name
    audio_name= audio_file_name.split('.')
    extension = audio_name.last
    audio_name.pop
    audio_name_2 = audio_name.to_sentence(two_words_connector: '_')
   "#{audio_name_2.gsub( /[^a-zA-Z0-9_\.]/, '_')}.#{extension}"
  end

  private
  def replace_audio
    self.audio_file_name = normalized_audio_file_name
  end
  

end
