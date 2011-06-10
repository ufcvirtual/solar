module DiscussionPostsHelper


  #Renderiza um post na tela de interação do portólio.
  #threaded indica se as respostas deste post devem ser renderizadas com ele.
  def show_post(post = nil, threaded=true)
    post_string = ""
    childs = {}
    editable = false
    childs_count = return_child_count(post.id)

    #Um post pode ser editado se é do próprio usuário e se não possui respostas.
    if (post.user_id == current_user.id) && (childs_count == 0)
        editable = true
    end

    #Recuperando posts filhos para renderização
    if threaded
      childs = return_posts_child(post[:id])
    end

    #Tratando nick para exibição
    nick = post.user_nick
    if nick.length > 15
      nick = nick.slice(0..12) + '...'
    end

    #Recuperando caminho da foto a ser carregada
    photo_url = ''
    if post.photo_file_name
      photo_url =  post.photo.url(:medium)
    else
      photo_url = 'no_image.png'
    end

    #Montando exibição do post e exibindo respostas recursivamente
    post_string << '<table border="0" cellpadding="0" cellspacing="0" width="95%" class="forum_post">
                    <tr>
                      <td class="forum_post_head_left">
                        <span alt="' << post.user_nick << '">' << nick << '</span><br />
                        <span class="forum_participant_profile" >'<< post.profile << '</span>
                      </td>
                      <td class="forum_post_head_right">
                        #
                      </td>
                    </tr>
                    <tr>
                      <td class="forum_post_content_left">'
    post_string <<      (image_tag photo_url, :alt => t(:mysolar_alt_img_user) + ' ' + post.user_nick)
    post_string << '     <div class="forum_participants_icons">
                            <span>' << (link_to (image_tag "icon_profile.png", :alt=>t(:icon_profile))) << '</span>
                            <span>' << (link_to (image_tag "icon_add_user.png", :alt=>t(:icon_add_participant))) << '</span>
                            <span>' << (link_to (image_tag "icon_chat.png", :alt=>t(:icon_chat))) << '</span>
                            <span>' << (link_to (image_tag "icon_message_participant.png", :alt=>t(:icon_send_email))) << '</span>
                          </div>
                        </td>
                        <td class="forum_post_content_right">
                          <div class="forum_post_inner_content" style="min-height:100px">'
    post_string <<      (sanitize post.content)

    post_string <<      ' </div>
                          <div class="forum_post_date">' << post[:updated_at].to_s(:discussion_post_pt_br) << '</div>
                          <div class="forum_post_date">'
                            if editable
    post_string <<      '     <a href="javascript:removePost(' << post[:id].to_s << ')">[excluir]</a>
                              <a href="javascript:setDiscussionPostId(' << post[:id].to_s << ')" class="updateDialogLink">[editar]</a>'
                            end
    post_string <<      '   <a href="javascript:setParentPostId(' << post[:id].to_s << ')" class="postDialogLink">[reponder]</a>
                          </div>
                        </td>
                      </tr>
                    </table>'

    childs.each do |child|
      post_string << '<div class="forum_post_child_ident">' << show_post(child, true) << '</div>'
    end

    return post_string
  end


######## MÉTODOS DE ACESSO À BASE DE DADOS ####################################



  #Recupera os posts de uma discussion.
  def return_discussion_posts(discussion_id = nil, plain_list = true)
    query = "SELECT dp.id, dp.discussion_id, dp.user_id, content, dp.created_at, dp.updated_at, dp.father_id, u.nick as user_nick, u.photo_file_name as photo_file_name, p.name as profile
             FROM discussion_posts dp
             INNER JOIN users u on u.id = dp.user_id
             INNER JOIN profiles p on p.id = dp.profile_id
             WHERE dp.discussion_id = '#{discussion_id}'"

    query << " and father_id is null" unless plain_list
    query << " order by created_at desc"
    
    return DiscussionPost.find_by_sql(query)
  end

  def return_posts_child(parent_id = -1)
    query = "SELECT dp.id, dp.discussion_id, dp.user_id, content, dp.created_at, dp.updated_at, dp.father_id, u.nick as user_nick, u.photo_file_name as photo_file_name, p.name as profile
             FROM discussion_posts dp
             INNER JOIN users u on u.id = dp.user_id
             INNER JOIN profiles p on p.id = dp.profile_id
             WHERE dp.father_id = '#{parent_id}'"
    query << " order by created_at desc"
    
    return DiscussionPost.find_by_sql(query)
  end

  def return_child_count(parent_id = -1)
    query = "SELECT dp.id
             FROM discussion_posts dp
             WHERE dp.father_id = '#{parent_id}'"
    return DiscussionPost.count_by_sql(query)
  end

end
