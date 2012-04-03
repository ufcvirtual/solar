module DiscussionPostsHelper

  # Verifica se a data em questão permite que o usuário possa postar no fórum
  def valid_date
    # Se estiver acessando o método do before_filter, o objeto "@discussion" não existe, logo tem que definí-lo 
    # a partir dos parâmetros enviados da página
    if params[:discussion_id]
      @discussion = Discussion.find(params[:discussion_id])
    end
    # Período ativo fórum
    schedule = Schedule.find(@discussion.schedule_id)

    # Verifica se a data de hoje está dentro do período ativo do fórum
    today_between_start_end = (schedule.start_date <= Date.today and Date.today <= schedule.end_date)
    # Variável que indicará se o usuário é o responsável pelo fórum
    user_is_class_responsible = false

    # Só precisa fazer a segunda verificação se a primeira for falsa. Ou seja, só precisa verificar o "tempo extra" e 
    # se o usuário é responsável daquele fórum se não estiver no prazo permitido
    unless today_between_start_end

      # Allocations tags relacionadas ao fórum
      active_tab = user_session[:tabs][:opened][user_session[:tabs][:active]]
      allocation_tag_id = active_tab[:url]['allocation_tag_id']
      allocations_tags = AllocationTag.find_related_ids(allocation_tag_id)

      # Pesquisa pelas allocations relacionadas ao usuário que possua um perfil de tipo igual a 'Profile_Type_Class_Responsible'
      query = <<SQL
          SELECT DISTINCT allocation.allocation_tag_id
            FROM profiles      AS profile 
            JOIN allocations   AS allocation ON allocation.profile_id = profile.id AND allocation.user_id = #{current_user.id} AND allocation.status = 1
           WHERE profile.types = #{Profile_Type_Class_Responsible} AND profile.status = true
SQL

      # Verificação se a allocation_tag de cada allocation retornada pelo query está inclusa nas allocations_tags relacionadas ao fórum
      for allocation in Allocation.find_by_sql(query)
        user_is_class_responsible = true if allocations_tags.include?(allocation.allocation_tag_id)
        break if user_is_class_responsible
      end

    end

    # Verifica se a data de hoje está dentro do período ativo do fórum
    today_between_start_end = (schedule.start_date <= Date.today and Date.today <= schedule.end_date)
    # Verifica se o usuário tem perfil de responsável para o fórum (ou allocations_tags relacionadas) 
    # e se hoje ultrapassou a data final da ativação do fórum em apenas os dias determinados por 'Forum_Responsible_Extra_Time'
    responsible_and_have_extra_time = (user_is_class_responsible and Date.today - schedule.end_date <= Forum_Responsible_Extra_Time)
    # Resultado da comparação final
    is_an_valid_date = today_between_start_end or responsible_and_have_extra_time

    # Se estiver acessando o método do before_filter, o parâmetro abaixo irá existir. 
    # Logo, se for o before_filter e tiver tentado postar no fórum indevidamente, aparecerá mensagem de erro
    if params[:discussion_id] and !is_an_valid_date
      flash[:error] = t(:forum_post_before_valid_date_error)
    end

    # Retorna o resultado final
    return is_an_valid_date
  end

  # Renderiza um post na tela de interação do portólio.
  # threaded indica se as respostas deste post devem ser renderizadas com ele.
  def show_post(post=nil, threaded=true, can_interact=false)
    childs = {}
    editable = false
    childs_count = DiscussionPost.child_count(post.id)

    #Um post pode ser editado se é do próprio usuário e se não possui respostas.
    editable = true if (post.user.id == current_user.id) && (childs_count == 0)

    #Recuperando posts filhos para renderização
    childs = DiscussionPost.posts_child(post[:id]) if threaded

    #Tratando nick para exibição
    nick = post.user_nick
    nick = nick.slice(0..12) + '...' if nick.length > 15

    #Recuperando caminho da foto a ser carregada
    photo_url = post.user.photo.url(:forum)

    #Montando exibição do post e exibindo respostas recursivamente
    post_string = '<table border="0" cellpadding="0" cellspacing="0" class="forum_post">'
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
      post_string << show_post(child, true, can_interact)
    end

    post_string <<      '</td>'
    post_string <<    '</tr>'
    post_string <<    '<tr>'

    post_string <<    '</tr>'
    post_string <<  '</table>'

    return post_string
  end

  ##
  # Utilizado na paginação
  ##
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
      form_string <<   '<h3>' << t(:forum_file_list) << '</h3>'

      form_string <<     '<ul class="forum_post_attachment_list">'
      post.discussion_post_files.each do |file|
        form_string <<    '<li>'
        form_string <<      '<a href="#">'<<(link_to file.attachment_file_name, :controller => "discussions", :action => "download_post_file", :idFile => file.id, :id => @discussion.id)<<'</a>&nbsp;&nbsp;'
        form_string <<   (link_to (image_tag "icon_delete_small.png", :alt => t(:forum_remove_file)), {:controller => "discussions", :action => "remove_attached_file", :idFile => file.id, :current_page => @current_page, :id => @discussion.id}, :confirm=>t(:forum_remove_file_confirm), :title => t(:forum_remove_file), 'data-tooltip' => t(:forum_remove_file)) if editable && can_interact
        form_string <<    '</li>'
      end
      form_string <<     '</ul>'
      form_string <<   '</div>'
    end

    return form_string
  end

  # Form de upload de arquivos dentro de um post
  def show_buttons(editable = false, can_interact = false, post=nil)
    post_string = '<div class="forum_post_buttons">'

    if editable && can_interact
      post_string << '<button type="button" class="btn btn_default forum_button_attachment" onclick="showUploadForm(\''<< post[:discussion_id].to_s << '\',\'' << post[:id].to_s << '\');">'<< t(:forum_attach_file) << (image_tag "icon_attachment.png", :alt => t(:forum_attach_file)) << '</button>' if editable and can_interact
      post_string << '<input type="button" onclick="removePost(' << post[:id].to_s << ')" class="btn btn_caution" value="' << t(:forum_show_remove) << '"/>'
      post_string << '<input type="button" onclick="setDiscussionPostId(' << post[:id].to_s << ')" class="btn btn_default updateDialogLink" value="' << t(:forum_show_edit) << '"/>'
      post_string << '<input type="button" onclick="setParentPostId(' << post[:id].to_s << ')" class="btn btn_default postDialogLink" value="' << t(:forum_show_answer) << '"/>'

    elsif editable && !can_interact
      post_string <<      '    <a class="forum_post_link_disabled forum_post_link_remove_disabled">' << t('forum_show_remove') << '</a>&nbsp;&nbsp;
                               <a class="forum_post_link_disabled">' << t('forum_show_edit') << '</a>&nbsp;&nbsp;
                               <a class="forum_post_link_disabled">' << t('forum_show_answer') << '</a>'
    elsif !editable && can_interact      
      post_string << '<input type="button" onclick="setParentPostId(' << post[:id].to_s << ')" class="btn btn_default postDialogLink" value="' << t(:forum_show_answer) << '" />'
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
