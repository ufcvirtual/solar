class QuestionItem < ActiveRecord::Base

  belongs_to :question

  has_many :exam_response

  validates :attachment, presence: true
  validates_attachment_size :attachment, less_than: 2.megabyte, message: ""
  validates_attachment_content_type_in_black_list :attachment

  has_attached_file :attachment,
                    path: ":rails_root/media/question/enunciation/item/:id_:basename.:extension",
                    url: "/media/question/enunciation/item/:id_:basename.:extension"
end
