module DiscussionPostsHelper

  def valid_date
    @discussion.start <= Date.today && Date.today <= @discussion.end
  end
  
  #Renderiza um post na tela de interação do portólio.
  #threaded indica se as respostas deste post devem ser renderizadas com ele.
  def show_post(post = nil, threaded=true)
    post_string = ""
    childs = {}
    editable = false
    childs_count = return_child_count(post.id)
    can_interact=true
    
    if(!valid_date)
      can_interact= false
    end
  
    #Um post pode ser editado se é do próprio usuário e se não possui respostas.
    if (post.user.id == current_user.id) && (childs_count == 0)
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
      photo_url = post.user.photo.url(:medium)
    else
      photo_url = 'no_image.png'
    end

    #Montando exibição do post e exibindo respostas recursivamente
    post_string << '<table border="0" cellpadding="0" cellspacing="0" class="forum_post">
                    <tr>
                      <td class="forum_post_head_left">
                        <span alt="' << post.user_nick << '">' << nick << '</span><br />
                        <span class="forum_participant_profile" >'<< post.profile << '</span>
                      </td>
                      <td class="forum_post_head_right">
                        <div class="forum_post_date">' << (l post[:updated_at], :format => :discussion_post ) << '</div>
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
                          <div class="forum_post_buttons">'
    if editable && can_interact
      post_string <<      '   <a href="javascript:removePost(' << post[:id].to_s << ')" class="forum_button forum_button_remove">' << t('forum_show_remove') << '</a>&nbsp;&nbsp;
                              <a href="javascript:setDiscussionPostId(' << post[:id].to_s << ')" class="forum_button updateDialogLink ">' << t('forum_show_edit') << '</a>&nbsp;&nbsp;
                              <a href="javascript:setParentPostId(' << post[:id].to_s << ')" class="postDialogLink forum_button">' << t('forum_show_answer') << '</a>' 
    elsif editable && !can_interact
      post_string <<      '    <strike> <a class="forum_post_link_disabled forum_post_link_remove_disabled">' << t('forum_show_remove') << '</a></strike>&nbsp;&nbsp;
                               <strike> <a  class="forum_post_link_disabled">' << t('forum_show_edit') << '</a></strike>&nbsp;&nbsp;
                               <strike><a   class="forum_post_link_disabled">' << t('forum_show_answer') << '</a></strike>'
    elsif !editable && can_interact 
         post_string <<      '   <a href="javascript:setParentPostId(' << post[:id].to_s << ')" class="postDialogLink forum_button">' << t('forum_show_answer') << '</a>'     
    elsif !editable && !can_interact
        post_string <<      '  <strike><a class="forum_post_link_disabled">' << t('forum_show_answer') << '</a></strike>'
    end
    post_string <<      '</div>
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

    
    return DiscussionPost.paginate_by_sql(query, {:per_page => Rails.application.config.items_per_page, :page => @current_page})

  end
  
  def count_discussion_posts(discussion_id = nil, plain_list = true)
    discussion_id = discussion_id.to_s
    
    query = "SELECT count (*) as total
             FROM discussion_posts dp
             WHERE dp.discussion_id = '#{discussion_id}'"
    query << " and father_id is null" unless plain_list
    return ActiveRecord::Base.connection.execute(query)[0]["total"]
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
