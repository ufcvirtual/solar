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

  accepts_nested_attributes_for :files, allow_destroy: true, reject_if: proc {|attributes| !attributes.include?(:attachment) || attributes[:attachment] == '0' || attributes[:attachment].blank?}

  before_create :set_level, :verify_level
  before_destroy :remove_all_files

  after_create :increment_counter
  after_destroy :decrement_counter, :update_acu, :remove_drafts_children, :decrement_counter_draft
  after_save :update_acu
  after_save :change_counter_draft, if: '!parent_id.nil? && draft_changed?'

  validates :content, :profile_id, presence: true

  validate :can_change?, if: 'merge.nil?'
  validate :parent_post, if: 'merge.nil? && !parent_id.blank?'

  validate :can_set_draft?, if: '!new_record? && draft_changed? && draft'

  before_save :set_parent, if: '!new_record? && parent_id_changed?'
  before_save :set_draft, if: 'draft.nil?'
  before_save :remove_draft_children, if: 'draft_changed? && draft'

  attr_accessor :merge

  def remove_drafts_children
    children.where(draft: true).map(&:delete_with_dependents)
  end

  def parent_post
    errors.add(:base, I18n.t('posts.error.draft')) if parent.draft
  end

  # cant change parent_id
  def set_parent
    self.parent_id = parent_id_was
    return true
  end

  def can_set_draft?
    errors.add(:base, I18n.t('posts.error.back_to_draft')) if children.where(draft: false).any?
  end

  def remove_draft_children
    # if changed from published to draft and all children are drafts
    if draft && !draft_was && children.where(draft: true).count == children.count
      # remove children
      children.map(&:destroy)
    end
  end

  # cant turn into draft a post already published
  def set_draft
    self.draft = (draft_was.blank? ? false : draft_was)
  end

  def verify_level
    raise 'level' if self.level > Discussion_Post_Max_Indent_Level
  end

  def verify_children
    errors.add(:base, I18n.t('posts.error.children')) if self.children.where(draft: false).any? && merge.nil?
  end

  def verify_children_with_raise
    if self.children.where(draft: false).any?
      errors.add(:base, I18n.t('posts.error.children'))
      raise 'children'
    end
  end

  def can_change?
    unless (user_id == User.current.try(:id) || (User.current.try(:id) == parent.try(:user_id) && !content_changed? && !draft_changed?))
      errors.add(:base, I18n.t('posts.error.permission'))
      raise 'permission'
    end
    unless discussion.user_can_interact?(user_id)
      errors.add(:base, I18n.t('posts.error.date_range_expired'))
      raise 'date_range_expired'
    end
  end
  
  def can_be_answered?
    (self.level < Discussion_Post_Max_Indent_Level) && !draft
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

   # obtain and reorder posts by its "children/grandchildren"
  def reordered_children(user_id, display_mode='three')
    if display_mode == 'list'
      children.where("draft = 'f' OR (draft = 't' AND user_id = ?)", user_id)
    else
      Post.reorder_by_latest_posts(children.where("draft = 'f' OR (draft = 't' AND user_id = ?)", user_id))
    end
  end

  def send_mail(at)
    post = Post.find(self.parent_id)
    user = User.find(post.user_id)
    notification_mail_post = NotificationMail.where(:user_id => post.user_id).pluck(:post).first
    if notification_mail_post.nil? || notification_mail_post

      subject = "#{I18n.t('posts.mail.subject')}"
      msg = self.template_mail(user, at.info, post)
      Thread.new do
        Job.send_mass_email([user.email], subject, msg)
      end

    end  

  end 

  def template_mail(user, info, post)
    %{
      <b>#{info} </b><br/>
      <br/>
      #{discussion.name}
      <br/>
      ________________________________________________________________________<br/>
      #{I18n.t('posts.mail.text')}
      <br/>
      #{user.name}: #{self.content}   
      ________________________________________________________________________<br/>
      #{I18n.t('posts.mail.text_resp')} #{post.content}
    }
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

    def decrement_counter_draft
      Post.decrement_counter('children_drafts_count', parent_id) unless parent.blank? || parent.try(:children_drafts_count) == 0 || !draft_was
    end

    def change_counter_draft
      if draft
        Post.increment_counter('children_drafts_count', parent_id)
      else
        Post.decrement_counter('children_drafts_count', parent_id) unless parent.try(:children_drafts_count) == 0
      end
    end

    def update_acu
      unless academic_allocation_user_id.blank?
        if (academic_allocation_user.grade.blank? && academic_allocation_user.working_hours.blank?)
          if academic_allocation_user.discussion_posts.where(draft: false).empty?
            academic_allocation_user.status = AcademicAllocationUser::STATUS[:empty]
          else
            academic_allocation_user.status = AcademicAllocationUser::STATUS[:sent]
          end
        else
          academic_allocation_user.new_after_evaluation = true
        end
        academic_allocation_user.merge = merge
        academic_allocation_user.save(validate: false)
      end
    end

    
end
