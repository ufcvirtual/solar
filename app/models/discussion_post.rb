class DiscussionPost < ActiveRecord::Base
  has_many :children, :class_name => "DiscussionPost", :foreign_key => "father_id"
  has_many :discussion_post_files
  belongs_to :father, :class_name => "DiscussionPost"

  belongs_to :discussion
  belongs_to :user

  #Falta implementar as validações aqui!!

  # Recupera todos os posts do usuario para a discussion passada
  def self.all_by_discussion_id_and_student_id(discussion_id, student_id)
    posts = ActiveRecord::Base.connection.select_all <<SQL
      SELECT t1.id,
             t2.user_id,
             t2.content
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
      SELECT dp.id, dp.discussion_id, dp.user_id, content, dp.created_at, dp.updated_at, dp.father_id, u.nick as user_nick, u.photo_file_name as photo_file_name, p.name as profile
             FROM discussion_posts dp
             INNER JOIN users u on u.id = dp.user_id
             INNER JOIN profiles p on p.id = dp.profile_id
             WHERE dp.father_id = #{parent_id}
       ORDER BY created_at desc
SQL
    
    return (posts.nil?) ? [] : posts
  end

  #Número de respostas diretas a um post
  def self.child_count(parent_id = -1)

    count = ActiveRecord::Base.connection.select_one <<SQL
      SELECT count (*)
        FROM discussion_posts dp
       WHERE dp.father_id = '#{parent_id}'
SQL
    return (count.nil?) ? 0 : count["count"].to_i
  end

  #Consulta página de postagens de uma discussion
  def self.discussion_posts(discussion_id = nil, plain_list = true, page = 1)
    query = "SELECT dp.id, dp.discussion_id, dp.user_id, content, dp.created_at, dp.updated_at, dp.father_id, u.nick as user_nick, u.photo_file_name as photo_file_name, p.name as profile
             FROM discussion_posts dp
             INNER JOIN users u on u.id = dp.user_id
             INNER JOIN profiles p on p.id = dp.profile_id
             WHERE dp.discussion_id = '#{discussion_id}'"
    query << " and father_id is null" unless plain_list
    query << " order by created_at desc"

    return DiscussionPost.paginate_by_sql(query, {:per_page => Rails.application.config.items_per_page, :page => page})
  end

  #Consulta número de postagens de uma discussion
  def self.count_discussion_posts(discussion_id = nil, plain_list = true)
    discussion_id = discussion_id.to_s

    query = "SELECT count (*) as total
             FROM discussion_posts dp
             WHERE dp.discussion_id = #{discussion_id}"
    query << " and father_id is null" unless plain_list
    return ActiveRecord::Base.connection.select_one(query)["total"].to_i

  end

end
