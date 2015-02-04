class Post < ActiveRecord::Base

  self.table_name = "discussion_posts"

  default_scope order: "updated_at DESC" # qualquer busca realizada nos posts de fórum serão ordenadas pela data decrescente

  belongs_to :profile
  belongs_to :parent, class_name: "Post"
  belongs_to :user

  belongs_to :academic_allocation, conditions: {academic_tool_type: 'Discussion'}

  has_many :children, class_name: "Post", foreign_key: "parent_id", dependent: :destroy
  has_many :files, class_name: "PostFile", foreign_key: "discussion_post_id", dependent: :destroy

  before_create :set_level
  before_destroy :remove_all_files

  validates :content, :profile_id, presence: true

  def can_be_answered?
    (self.level < Discussion_Post_Max_Indent_Level)
  end

  ## Retorna o post "avô", ou seja, o post do nível mais alto informado em "post_level"
  def grandparent(post_level, post = nil)
    if level == post_level
      return ["date" => post.updated_at, "grandparent_id" => id]
    else
      Post.find(parent_id).grandparent(post_level, (post || self)) unless parent_id.nil?
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
    date = [(children.any? ? children.map(&:get_latest_date) : updated_at)].flatten
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

end
