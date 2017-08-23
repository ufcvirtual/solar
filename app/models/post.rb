class Post < ActiveRecord::Base

  self.table_name = 'discussion_posts'

  belongs_to :profile
  belongs_to :parent, class_name: 'Post'
  belongs_to :user

  belongs_to :academic_allocation, conditions: { academic_tool_type: 'Discussion' }
  belongs_to :academic_allocation_user

  validates :parent, presence: true, unless: 'parent_id.blank?'
  before_destroy :verify_children_with_raise, :can_change?, if: 'merge.nil?'
  validate :verify_children, on: :update

  has_many :children, class_name: 'Post', foreign_key: 'parent_id', dependent: :destroy
  has_many :files, class_name: 'PostFile', foreign_key: 'discussion_post_id', dependent: :destroy


  before_create :set_level, :verify_level
  before_destroy :remove_all_files

  after_create :increment_counter
  after_destroy :decrement_counter, :update_acu
  after_save :update_acu, on: :update

  validates :content, :profile_id, presence: true

  validate :can_change?, if: 'merge.nil?'

  attr_accessor :merge

  def verify_level
    raise 'level' if self.level > Discussion_Post_Max_Indent_Level
  end

  def verify_children
    errors.add(:base, I18n.t('posts.error.children')) if self.children.any? && merge.nil?
  end

  def verify_children_with_raise
    if self.children.any?
      errors.add(:base, I18n.t('posts.error.children'))
      raise 'children'
    end
  end

  def can_change?
    unless user_id == User.current.try(:id)
      errors.add(:base, I18n.t('posts.error.permission'))
      raise 'permission'
    end
    unless discussion.user_can_interact?(user_id)
      errors.add(:base, I18n.t('posts.error.date_range_expired'))
      raise 'date_range_expired'
    end
  end
  
  def can_be_answered?
    (self.level < Discussion_Post_Max_Indent_Level)
  end

  ## Retorna o post 'avo', ou seja, o post do nivel mais alto informado em 'post_level'
  def grandparent(post_level=nil)
    unless post_level.nil?
      return nil if (post_level > level)
      (parent.nil? ? self : ((parent.level == post_level) ? parent : parent.grandparent(post_level)))
    else
      (parent.try(:grandparent) || parent || self)
    end
  end

  def discussion
    Discussion.find(academic_allocation.academic_tool_id)
  end

  def to_mobilis
    attachments = []
    files.map { |file| attachments << {type: file.attachment_content_type, name: file.attachment_file_name, link: Rails.application.routes.url_helpers.download_post_post_file_path(post_id: id, id: file.id)} }

    {
      id: id,
      profile_id: profile_id,
      discussion_id: discussion.id,
      user_id: user_id,
      user_nick: user.nick,
      level: level,
      content: content,
      updated_at: updated_at,
      attachments: attachments
    }
  end

  ## Return latest date considering children
  def get_latest_date
    date = [(children_count <= 0 ? self.updated_at : children.map(&:get_latest_date))].flatten.compact
    date.sort.last
  end

  ## Recupera os posts mais recentes dos niveis inferiores aos posts analisados e, então,
  ## reordena analisando ou as datas dos posts em questão ou a data do "filho/neto" mais recente
  def self.reorder_by_latest_posts(posts)
    return posts.sort_by{|post|
      post.get_latest_date
    }.reverse
  end

  def delete_with_dependents
    children.map(&:delete_with_dependents)
    remove_all_files
    self.delete
  end

  private

    def set_level
      self.level = parent.level.to_i + 1 unless parent_id.nil?     
    end

    def remove_all_files
      files.each do |file|
        file.delete
        File.delete(file.attachment.path) if File.exist?(file.attachment.path)
      end
    end

    def increment_counter
      Post.increment_counter('children_count', parent_id)
    end

    def decrement_counter
      Post.decrement_counter('children_count', parent_id) unless parent.blank? || parent.try(:children_count) == 0
    end

    def update_acu
      unless academic_allocation_user_id.blank?
        if (academic_allocation_user.grade.blank? && academic_allocation_user.working_hours.blank?)
          if academic_allocation_user.discussion_posts.empty?
            academic_allocation_user.status = AcademicAllocationUser::STATUS[:empty]
          else
            academic_allocation_user.status = AcademicAllocationUser::STATUS[:sent]
          end
        else
          academic_allocation_user.new_after_evaluation = true
        end
        academic_allocation_user.save(validate: false)
      end
    end
end
