module DiscussionPostsHelper


  #Renderiza um post na tela de interação do portólio.
  #show_child indica se as respostas deste post devem ser renderizadas com ele.
  def show_post(post = nil, show_child=true)
    @post = post
    render '/discussions/post'
  end


  #Recupera os posts de uma discussion.
  def return_discussion_posts(discussion_id = nil, show_child=true)
    query = "select
                id, discussions_id, users_id, content, father_id, created_at, updated_at
             from
                discussion_posts
             where
                discussions_id = '#{discussion_id}'"
    if !(show_child)
      query += " and father_id is null"
    end
    query += " order by created_at desc"
    
    return DiscussionPost.find_by_sql(query)
  end

end
