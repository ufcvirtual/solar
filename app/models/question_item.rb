class QuestionItem < ActiveRecord::Base

  belongs_to :question

  has_many :exam_responses

  validates_attachment_size :item_image, less_than: 2.megabyte, message: ''
  validates_attachment_content_type :item_image, content_type: /^image\/(jpg|jpeg|pjpeg|png|x-png|gif)$/, message: 'file type is not allowed (only jpeg/png/gif images)'

  validates :description, presence: true

  validates :img_alt, presence: true, unless: lambda { |c| c[:item_image].blank? }

  has_attached_file :item_image,
                    path: ':rails_root/media/questions/items/:id_:basename.:extension',
                    url: '/media/questions/items/:id_:basename.:extension'

  before_destroy :can_destroy?

	def self.list(question_id)
  	QuestionItem.where(question_id: question_id)
      .select('DISTINCT question_items.id, question_items.description, question_items.value')
  end

  def can_destroy?
    raise 'in_use' if exam_responses.any?
  end

end
