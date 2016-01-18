class QuestionItem < ActiveRecord::Base

  belongs_to :question

  has_many :exam_responses

  validates_attachment_size :item_image, less_than: 2.megabyte, message: ''
  validates_attachment_content_type :item_image, content_type: /^image\/(jpg|jpeg|pjpeg|png|x-png|gif)$/, message: 'file type is not allowed (only jpeg/png/gif images)'

  validates :description, presence: true

  validate :alt, if: '(!item_image_file_name.blank? && img_alt.blank?)'

  has_attached_file :item_image,
                    styles: { small: '120x120'},
                    path: ':rails_root/media/questions/items/:id_:basename.:extension',
                    url: '/media/questions/items/:id_:basename.:extension'

  before_destroy :can_destroy?

	def self.list(question_id)
  	QuestionItem.where(question_id: question_id)
      .select('DISTINCT question_items.id, question_items.description, question_items.value, question_items.item_image_file_name, question_items.item_image_content_type, question_items.item_image_file_size, question_items.item_image_updated_at, question_items.img_alt')
  end

  def can_destroy?
    raise 'in_use' if exam_responses.any?
  end

  def alt
    errors.add(:base, I18n.t('questions.error.alt'))
  end

end
