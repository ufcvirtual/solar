class PublicFile < ActiveRecord::Base

  FILESIZE = 20.megabyte

  before_destroy :can_remove?

  belongs_to :user
  belongs_to :allocation_tag

  has_attached_file :attachment,
    path: ":rails_root/media/assignment/public_area/:id_:basename.:extension",
    url: "/media/assignment/public_area/:id_:basename.:extension"

  validates :attachment_file_name, presence: true

  validates_attachment_size :attachment, less_than: FILESIZE, message: ""

  validates_attachment_content_type_in_black_list :attachment
  do_not_validate_attachment_file_type :attachment
  
  before_save :verify_offer, if: -> {merge.nil?}

  attr_accessor :merge

  def order
   'attachment_updated_at DESC'
  end

  def can_remove?
    raise CanCan::AccessDenied unless user_id == User.current.id
  end

  def verify_offer
    offer = AllocationTag.find(allocation_tag_id).offers.first
    if offer.end_date < Date.current
      errors.add(:base, I18n.t('public_files.error.offer_end')) if offer.end_date < Date.current
      raise 'offer_end'
    end
    if offer.start_date > Date.current
      errors.add(:base, I18n.t('public_files.error.offer_start')) if offer.start_date > Date.current
      raise 'offer_start'
    end
  end

end
