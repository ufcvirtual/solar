class Post < ActiveRecord::Base
  self.table_name = "discussion_posts"

  default_scope order: "updated_at DESC" # qualquer busca realizada nos posts de fórum serão ordenadas pela data decrescente

  has_many :children, class_name: "Post", foreign_key: "parent_id"
  has_many :files, class_name: "PostFile", foreign_key: "discussion_post_id"

  belongs_to :profile
  belongs_to :parent, class_name: "Post"
  belongs_to :discussion
  belongs_to :user

  validates :content, presence: true

  validates_each :discussion_id do |record, attr, value|
    parent = record.parent
    record.errors.add(attr) if not parent.nil? and parent.discussion_id != value
  end

  def can_be_answered?
    (self.level < Discussion_Post_Max_Indent_Level)
  end

  def to_mobilis
    attachments = []
    files.map { |file| attachments << {type: file.attachment_content_type, name: file.attachment_file_name, link: Rails.application.routes.url_helpers.download_post_post_file_path(post_id: id, id: file.id)} }
    
    {
      id: id,
      profile_id: profile_id,
      discussion_id: discussion_id,
      user_id: user_id,
      user_nick: user.nick,
      level: level,
      content: content,
      updated_at: updated_at,
      attachments: attachments
    }
  end

  ## Retorna o post "avô", ou seja, o post do nível mais alto informado em "post_level"
  def grandparent(post_level, post = nil)
    if level == post_level
      return ["date" => post.updated_at, "grandparent_id" => id]
    else
      Post.find(parent_id).grandparent(post_level, (post || self))
    end
  end

  ## Recupera os posts mais recentes dos niveis inferiores aos posts analisados e, então, 
  ## reordena analisando ou as datas dos posts em questão ou a data do "filho/neto" mais recente
  def self.reorder_by_latest_posts(latest_posts, posts) 
    unless posts.empty? 
      # dos posts mais recentes de uma discussion, recupera sua data e o valor do "avô" de todos os posts que têm level maior que o que estou ordenando
      lp_info = latest_posts.collect{|lp| lp.grandparent(posts.first.level) if lp.level > posts.first.level}
      # recupera o mais recente dos agrupados, ou seja, se, para um mesmo "post avô", há vários níveis, em cada nível vai ter seu respectivo post mais atual. 
      # ao definir quais posts são "netos" do mesmo post do level inicial, pode-se saber qual, realmente, é o mais recente de todos e guardar sua data
      lp_info = lp_info.compact.flatten.group_by{|lp| lp["grandparent_id"]}.collect{|lp| lp[1][0]}

      # reordenar os posts a partir de suas datas ou do "neto" mais recente
      posts = posts.sort{|post1, post2|
        # recupera o "neto" mais atualizado do post a ser ordenado
        lp_info1, lp_info2 = lp_info.find{|lp| lp["grandparent_id"] == post1.id}, lp_info.find{|lp| lp["grandparent_id"] == post2.id} 

        # recupera a data mais recente entre o post a ser ordenado e seu "neto" mais recente
        last_post1 = (((not lp_info1.nil?) and lp_info1["date"] > post1.updated_at) ? lp_info1["date"] : post1.updated_at)
        last_post2 = (((not lp_info2.nil?) and lp_info2["date"] > post2.updated_at) ? lp_info2["date"] : post2.updated_at)

        # ordena
        (last_post2 <=> last_post1)
      }
    end

    return posts
  end

end
