module DiscussionPostsHelper


  #Renderiza um post na tela de interação do portólio.
  #show_child indica se as respostas deste post devem ser renderizadas com ele.
  def show_post(post = nil, show_child=true)
    @post = post
    render '/discussions/post'
  end


  #Recupera os posts de uma discussion.
  def return_discussion_posts(discussion_id = nil, show_child=true)
    query = "SELECT dp.id, dp.discussion_id, dp.user_id, content, dp.created_at, dp.updated_at, dp.father_id, u.nick as user_nick, u.photo_file_name as photo_file_name, p.name as profile
             FROM discussion_posts dp
             INNER JOIN users u on u.id = dp.user_id
             INNER JOIN profiles p on p.id = dp.profile_id
             WHERE dp.discussion_id = '#{discussion_id}'"

    if !(show_child)
      query += " and father_id is null"
    end
    query += " order by created_at desc"
    
    return DiscussionPost.find_by_sql(query)
    # return DiscussionPost.find(:all, :conditions => ["discussions_id = ?",discussion_id])
  end

end
