module DiscussionPostsHelper

  def valid_date
    schedule = Schedule.find(@discussion.schedule_id)
    schedule.start_date <= Date.today && Date.today <= schedule.end_date
  end

  # Renderiza um post na tela de interação do portólio.
  # threaded indica se as respostas deste post devem ser renderizadas com ele.
  def show_post(post = nil, threaded=true)
    post_string = ""
    childs = {}
    editable = false
    childs_count = DiscussionPost.child_count(post.id)
    can_interact= valid_date

    #Um post pode ser editado se é do próprio usuário e se não possui respostas.
    editable = true if (post.user.id == current_user.id) && (childs_count == 0)

    #Recuperando posts filhos para renderização
    childs = DiscussionPost.posts_child(post[:id]) if threaded

    #Tratando nick para exibição
    nick = post.user_nick
    nick = nick.slice(0..12) + '...' if nick.length > 15

    #Recuperando caminho da foto a ser carregada
    photo_url = 'no_image.png'
    photo_url = post.user.photo.url(:forum) if post.photo_file_name

    #Montando exibição do post e exibindo respostas recursivamente
    post_string <<
    post_string << '<table border="0" cellpadding="0" cellspacing="0" class="forum_post">'
    post_string <<    '<tr>'
    post_string <<      '<td rowspan="3" class="forum_post_icon">'
    post_string <<        (image_tag photo_url, :alt => t(:mysolar_alt_img_user) + ' ' + post.user_nick)
    post_string <<      '</td>'
    post_string <<      '<td class="forum_post_head">'
    post_string <<        '<div class="forum_post_author">'
    post_string <<          '<div class="forum_participant_nick" alt="' << post.user_nick << '">' << post.user_nick << '</div>'
    post_string <<          '<div class="forum_participant_profile" >'<< post.profile << '</div>'
    post_string <<        '</div>'
    post_string <<        '<div class="forum_post_date">' << (l post[:updated_at], :format => :discussion_post_date ) << '<br />' << (l post[:updated_at], :format => :discussion_post_hour ) << '</div>'
    post_string <<      '</td>'
    post_string <<    '</tr>'
    post_string <<    '<tr>'
    post_string <<      '<td class="forum_post_content" colspan="2">'
    post_string <<        '<div class="forum_post_inner_content">' << (sanitize post.content) <<' </div>'

    #Apresentando os arquivos do post
    post_string << show_attachments(post, editable, can_interact)

    #Exibindo botões de edição, resposta e exclusão
    post_string << show_buttons(editable,can_interact, post)

    #Renderizando as respostas ao post
    childs.each do |child|
      post_string << show_post(child, true)
    end

    post_string <<      '</td>'
    post_string <<    '</tr>'
    post_string <<  '</table>'

    return post_string
  end

  # Utilizado na paginação
  def count_discussion_posts(discussion_id = nil, plain_list = true)
    DiscussionPost.count_discussion_posts(discussion_id, plain_list)
  end

  ##
  # Utilizado nas consultas para portlets
  ##
  def list_portlet_discussion_posts(allocations)
    all_discussions = Discussion.all_by_allocations(allocations)

    return [] if all_discussions.empty? # sem discussions

    # lista de ids das discussions
    discussions_ids = []
    all_discussions.each do |discussion|
      discussions_ids << discussion.id
    end
    
    DiscussionPost.recent_by_discussions(discussions_ids.join(','), Rails.application.config.items_per_page.to_i)
  end

  private

  # Link para o lightbox de upload
  def show_attachments(post = nil, editable = false, can_interact = false)
    #Cabeçalho
    form_string =  ''
   
    #Lista de arquivos
    unless post.discussion_post_files.count == 0
      form_string <<   '<div class="forum_post_attachment">'
      form_string <<   '<div><b>' << t(:forum_file_list) << '</b></div>'

      form_string <<      '<ul class="forum_post_attachment_list">'
      post.discussion_post_files.each do |file|
        form_string <<   '<li>'
        form_string <<   '<a href="#">'<<(link_to file.attachment_file_name, :controller => "discussions", :action => "download_post_file", :idFile => file.id, :id => @discussion.id)<<'</a>&nbsp;&nbsp;'
        form_string <<   (link_to (image_tag "discussion_file_remove.png", :alt => t(:forum_remove_file)), {:controller => "discussions", :action => "remove_attached_file", :idFile => file.id, :current_page => @current_page, :id => @discussion.id}, :confirm=>t(:forum_remove_file_confirm), :title => t(:forum_remove_file)) if editable && can_interact
        form_string <<   '</li>'
      end
      form_string <<      '</ul>'
      form_string <<      '</div>'
    end

    return form_string
  end

  # Form de upload de arquivos dentro de um post
  def show_buttons(editable = false, can_interact = false, post=nil)
    post_string = '<div class="forum_post_buttons">'

    if editable && can_interact
      post_string << '<a href="#" class="forum_button_attachment" onclick="showUploadForm(\''<< post[:discussion_id].to_s << '\',\'' << post[:id].to_s << '\');">'<< t(:forum_attach_file) << '&nbsp;' << (image_tag "more.png", :alt => t(:forum_attach_file)) << '</a>' if editable && can_interact
      post_string << '<input type="button" onclick="removePost(' << post[:id].to_s << ')" class="btn btn_caution" value="' << t(:forum_show_remove) << '"/>'
      post_string << '<input type="button" onclick="setDiscussionPostId(' << post[:id].to_s << ')" class="btn btn_default updateDialogLink" value="' << t(:forum_show_edit) << '"/>'
      post_string << '<input type="button" onclick="setParentPostId(' << post[:id].to_s << ')" class="btn btn_default postDialogLink" value="' << t(:forum_show_answer) << '"/>'

    elsif editable && !can_interact
      post_string <<      '    <a class="forum_post_link_disabled forum_post_link_remove_disabled">' << t('forum_show_remove') << '</a>&nbsp;&nbsp;
                               <a class="forum_post_link_disabled">' << t('forum_show_edit') << '</a>&nbsp;&nbsp;
                               <a class="forum_post_link_disabled">' << t('forum_show_answer') << '</a>'
    elsif !editable && can_interact      
      post_string << '<input type="button" onclick="setParentPostId(' << post[:id].to_s << ')" class="btn btn_default postDialogLink" value="' << t(:forum_show_answer) << '"'

    elsif !editable && !can_interact
      post_string <<      '  <a class="forum_post_link_disabled">' << t('forum_show_answer') << '</a>'
    end
    post_string <<      '</div></div>'

    return post_string
  end

  # Verifica se a messagem foi postada hoje ou não!
  def posted_today?(message_datetime)
    message_datetime === Date.today
  end

  #retorna discussions onde o usuário pode interagir.
  def permitted_discussions(offer_id = nil, group_id = nil, discussion_id = nil)

    # uma discussion eh ligada a uma turma ou a uma oferta
    if !(group_id.nil? && offer_id.nil?)
      query_discussions = "SELECT distinct d.id as discussionid, d.name
                       FROM discussions d
                       LEFT JOIN allocation_tags at ON d.allocation_tag_id = at.id"
      unless (offer_id.nil? && group_id.nil?)
        query_discussions << " and ( "

        temp_query_discussions = []
        temp_query_discussions << " at.group_id in ( #{group_id} )" unless group_id.nil?
        temp_query_discussions << " at.offer_id in ( #{offer_id} )" unless offer_id.nil?
        temp_query_discussions << " at.group_id in ( select id from groups where offer_id = #{offer_id} ) "  unless offer_id.nil?

        query_discussions << temp_query_discussions.join(' OR ')

        query_discussions << "     ) "
      end

      #vê se passou discussion
      query_discussions += " and d.id=#{discussion_id} " unless discussion_id.nil?

      return Discussion.find_by_sql(query_discussions)
    end
  end

end
