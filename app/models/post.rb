class Post < ActiveRecord::Base

  self.table_name = 'discussion_posts'

  belongs_to :profile
  belongs_to :parent     , class_name: 'Post'
  belongs_to :user

  belongs_to :academic_allocation, conditions: { academic_tool_type: 'Discussion' }

  has_many :children     , class_name: 'Post', foreign_key: 'parent_id', dependent: :destroy
  has_many :files        , class_name: 'PostFile', foreign_key: 'discussion_post_id', dependent: :destroy

  before_create :set_level, :increment_counter
  before_destroy :remove_all_files, :decrement_counter

  validates :content, :profile_id, presence: true

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
    date = [(children_count.zero? ? updated_at : children.map(&:get_latest_date))].flatten
    date.sort.last
  end

  ## Recupera os posts mais recentes dos niveis inferiores aos posts analisados e, então,
  ## reordena analisando ou as datas dos posts em questão ou a data do "filho/neto" mais recente
  def self.reorder_by_latest_posts(posts)
    return posts.sort_by{|post|
      post.get_latest_date
    }.reverse
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
      Post.decrement_counter('children_count', parent_id)
    end
end
