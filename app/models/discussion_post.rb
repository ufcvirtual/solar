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
end
