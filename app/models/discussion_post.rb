class DiscussionPost < ActiveRecord::Base
  has_many :children, :class_name => "DiscussionPost", :foreign_key => "parent_id"
  has_many :discussion_post_files
  belongs_to :parent, :class_name => "DiscussionPost"

  belongs_to :discussion
  belongs_to :user

  validates :content, :presence => true

  #Falta implementar as validações aqui!!

  # Recupera todos os posts do usuario para a discussion passada
  def self.all_by_discussion_id_and_student_id(discussion_id, student_id)
    posts = ActiveRecord::Base.connection.select_all <<SQL
      SELECT t1.id,
             t2.user_id,
             t2.content,
             t2.created_at AS posted
        FROM discussions      AS t1
        JOIN discussion_posts AS t2 ON t2.discussion_id = t1.id
       WHERE t2.user_id = #{student_id}
         AND t1.id = #{discussion_id}
       ORDER BY t2.created_at, t2.updated_at
SQL
    return (posts.nil?) ? [] : posts
  end

  #Respostas diretas a um post
  def self.posts_child(parent_id = -1)
    #posts = ActiveRecord::Base.connection.select_all
    posts = DiscussionPost.find_by_sql <<SQL
      SELECT dp.id, dp.discussion_id, dp.user_id, dp.content, dp.level, dp.created_at, dp.updated_at,
             dp.parent_id, u.nick as user_nick, u.photo_file_name as photo_file_name, p.name as profile
        FROM discussion_posts dp
  INNER JOIN users u on u.id = dp.user_id
  INNER JOIN profiles p on p.id = dp.profile_id
       WHERE dp.parent_id = #{parent_id}
       ORDER BY created_at desc
SQL

    return (posts.nil?) ? [] : posts
  end

  #Número de respostas diretas a um post
  def self.child_count(parent_id = -1)

    count = ActiveRecord::Base.connection.select_one <<SQL
      SELECT count (*)
        FROM discussion_posts dp
       WHERE dp.parent_id = '#{parent_id}'
SQL
    return (count.nil?) ? 0 : count["count"].to_i
  end

  #Consulta página de postagens de uma discussion
  def self.discussion_posts(discussion_id = nil, plain_list = true, page = 1)
    query = "SELECT dp.id, dp.discussion_id, dp.user_id, dp.content, dp.created_at,
                    dp.updated_at, dp.parent_id, dp.level, u.nick as user_nick,
                    u.photo_file_name as photo_file_name, p.name as profile
               FROM discussion_posts dp
         INNER JOIN users    u on u.id = dp.user_id
         INNER JOIN profiles p on p.id = dp.profile_id
              WHERE dp.discussion_id = '#{discussion_id}'"
    query << " AND parent_id is null" unless plain_list
    query << " ORDER BY created_at DESC"

    return DiscussionPost.paginate_by_sql(query, {:per_page => Rails.application.config.items_per_page, :page => page})
  end

  ##
  # Consulta retorna postagens mais recentes dos dados forúns
  ##
  def self.recent_by_discussions(discussions, limit = 0, content_size = 255)

    query = <<SQL
        SELECT id, user_id, discussion_id, profile_id,
               substring("content" from 0 for #{content_size}) AS content,
               created_at, updated_at, parent_id
          FROM discussion_posts
         WHERE discussion_id IN (#{discussions})
         ORDER BY updated_at DESC
SQL

    query << "LIMIT #{limit}" if limit > 0

    return DiscussionPost.find_by_sql(query)

  end

  def can_be_answered?
    if self.level < Discussion_Post_Max_Indent_Level
      return true
    else
      return false
    end
  end

end
