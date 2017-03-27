class PostFile < ActiveRecord::Base

  self.table_name = "discussion_post_files"

  belongs_to :post, foreign_key: "discussion_post_id"

  has_one :user, through: :post

  validate :can_change?, if: 'merge.nil?'
  before_destroy :can_change?, if: 'merge.nil?'

  validates :attachment_file_name, :presence => true
  validates_attachment_size :attachment, :less_than => 10.megabyte, :message => " "
  validates_attachment_content_type_in_black_list :attachment

  has_attached_file :attachment,
    :path => ":rails_root/media/discussions/post/:id_:basename.:extension",
    :url => "/media/discussions/post/:id_:basename.:extension"

  attr_accessor :merge

  def can_change?
    unless post.user_id == User.current.try(:id)
      errors.add(:base, I18n.t('posts.error.permission'))
      raise 'permission'
    end
    unless post.discussion.in_time?
      errors.add(:base, I18n.t('posts.error.date_range_expired'))
      raise 'date_range_expired'
    end
  end

end
