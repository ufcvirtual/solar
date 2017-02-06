class QuestionAudio < ActiveRecord::Base
  belongs_to :question

  validates :audio, presence: true
  validates :audio_description, presence: true, if: 'description.blank?'
  validates :description, presence: true, if: 'audio_description.blank?'

  validates_attachment_size :audio, less_than: 10.megabyte, message: ''
  validates_attachment_content_type :audio, content_type: /^audio\/(mpeg|x-mpeg|mp3|x-mp3|mpeg3|x-mpeg3|mpg|x-mpg|x-mpegaudio)$/, message: I18n.t('questions.error.wrong_type')

  has_attached_file :audio,
                    path: ':rails_root/media/questions/audios/:id_:basename.:extension',
                    url: '/media/questions/audios/:id_:basename.:extension'

  def self.list(question_id)
    QuestionAudio.where(question_id: question_id)
      .select('DISTINCT question_audios.id, question_audios.audio_file_name, question_audios.audio_content_type, question_audios.audio_file_size, question_audios.audio_updated_at, description, audio_description')
  end
end
