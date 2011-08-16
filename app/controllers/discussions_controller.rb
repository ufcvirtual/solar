class DiscussionsController < ApplicationController

  include DiscussionPostsHelper

  load_and_authorize_resource :except => [:list, :attach_file, :download_post_file, :remove_attached_file, :show_posts, :post_file_upload] #Setar permissoes!!!!!
  before_filter :prepare_for_pagination
  
  def list

    authorize! :list, Discussion

    # pegando dados da sessao e nao da url
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    offer_id = session[:opened_tabs][session[:active_tab]]["offers_id"]

    if group_id.nil?
      group_id = -1
    end
    
    if offer_id.nil?
      offer_id = -1
    end

    # retorna os fóruns da turma
    # at.id as id, at.offer_id as offerid,l.allocation_tag_id as alloctagid,l.type_lesson, privacy,description,
    query = "SELECT * 
              FROM 
                (SELECT d.name, d.id, d.start, d.end, d.description 
                 FROM discussions d 
                 INNER JOIN allocation_tags t on d.allocation_tag_id = t.id
                 INNER JOIN groups g on g.id = t.group_id
                 WHERE g.id = #{group_id}
              
                 UNION ALL
              
                 SELECT d.name, d.id, d.start, d.end, d.description 
                 FROM discussions d 
                 INNER JOIN allocation_tags t on d.allocation_tag_id = t.id
                 INNER JOIN offers o on o.id = t.offer_id
                 WHERE o.id = #{offer_id}
                ) as available_discussions
              ORDER BY start;"

    @discussions = Discussion.find_by_sql(query)

  end

  def show
    discussion_id = params[:discussion_id]
    discussion_id = params[:id] if discussion_id.nil?
    @display_mode = params[:display_mode]

    if @display_mode.nil?
      @display_mode = session[:forum_display_mode]
    else
      session[:forum_display_mode] = @display_mode
    end

    @discussion = Discussion.find(discussion_id)
    if @display_mode == "PLAINLIST"
      @posts = DiscussionPost.discussion_posts(@discussion.id, true,@current_page)
    else
      @posts = DiscussionPost.discussion_posts(@discussion.id, false,@current_page)
    end
  end

  def new_post
    @display_mode = params[:display_mode]
    discussion_id = params[:discussion_id]
    content       = params[:content]
    parent_id     = params[:parent_post_id]
    profile_id    = -1
   
    @discussion = Discussion.find_by_id(discussion_id)

    #Investigando um perfil com permissão para o usuário
    has_permission = false
    profile_id = find_activity_user_profile_with_permission(@discussion.allocation_tag, current_user, 'discussions', 'new_post')
    if profile_id > 0
      has_permission = true
    end
    
    #Usuário só pode criar posts no período ativo do fórum
    if (valid_date && has_permission)
      begin
        ActiveRecord::Base.transaction do
          #Criando nova postagem
          new_discussion_post = DiscussionPost.new :discussion_id => discussion_id, :user_id => current_user.id, :profile_id => profile_id, :content => content, :father_id => parent_id
          new_discussion_post.save!
        end
      rescue Exception => error
        flash[:error] = error.message
      end

      #Se a exibição for do tipo PLAINLIST, a nova postagem aparece no inicio, logo, não devemos manter a página atual

      hold_pagination unless (@display_mode == "PLAINLIST" or parent_id == "")
    
    end   

    redirect_to "/discussions/show/" << discussion_id
  end

  def remove_post
    @display_mode = params[:display_mode]
    discussion_id = params[:discussion_id]
    discussion_post_id = params[:discussion_post_id]
    
    #Relação de usuário com o post
    #(# Só o dono do post pode apagar, se estiver no período ativo do fórum e se a postagem não tiver resposta(filhos))
    
    @discussion_post= DiscussionPost.find_by_id(discussion_post_id)
    @discussion= Discussion.find_by_id(discussion_id)
    ActiveRecord::Base.transaction do
      if (owned_by_current_user) &&
          (valid_date)&&
          (has_no_response)

        filenameArray = []
        error = false
        path = ""
        
        
        #Removendo arquivos da postagem na base de dados
        @discussion_post.discussion_post_files.each do |file|
          filenameArray.push("#{file.id.to_s}_#{file.attachment_file_name}")
          error = true unless DiscussionPostFile.delete(file.id)
        end

        #Removendo a postagem propriamente dita
        error = true unless DiscussionPost.delete(discussion_post_id)

        #caso não tenha havido problema algum, remove o arquivo do disco.
        unless error
          filenameArray.each do |filename|
            path = "#{::Rails.root.to_s}/media/discussion/post/#{filename}"
            File.delete(path) if File.exist?(path)
          end
        else
          #dá um rollback malvado
        end
        flash[:error] = "[Erro removendo postagem]" unless error == false # INTERNACIONALIZAR!!!!!!!!!!!
      end
    end
    hold_pagination
    redirect_to "/discussions/show/" << discussion_id
  end

  def update_post
    discussion_id = params[:discussion_id]
    discussion_post_id = params[:discussion_post_id]
    new_content = params[:content]

    #(# Só o dono do post pode editar, se estiver no período ativo do fórum e se a postagem não tiver resposta(filhos))
    @discussion_post= DiscussionPost.find_by_id(discussion_post_id)
    @discussion= Discussion.find_by_id(discussion_id)
    
    if (owned_by_current_user) &&
        (valid_date)&&
        (has_no_response)
        
      post = DiscussionPost.find(discussion_post_id);
      post.update_attributes({:content => new_content})

    end

    hold_pagination
    redirect_to "/discussions/show/" << discussion_id
  end

  #Formulário de upload exibido numa lightbox
  def post_file_upload
    render :layout => false
  end

  #Download de arquivo anexo
  def download_post_file
    post_file_id = params[:idFile]
    file_ = DiscussionPostFile.find(post_file_id)
    filename = file_.attachment_file_name

    prefix_file = file_.id # id da tabela discussion_post_file para diferenciar os arquivos
    path_file = "#{::Rails.root.to_s}/media/discussion/post/"

    redirect_error = {:action => 'show', :id => params[:id], :idFile => post_file_id}
    # recupera arquivo
    
    download_file(redirect_error, path_file, filename, prefix_file)
  end

  #Envio de arquivo anexo
  def attach_file
    #CHECAR SE A PERMISSAO ESTÁ APENAS PARA O DONO DA POSTAGEM!!!

    @display_mode = params[:display_mode]
    discussion_id = params[:id]
    post_id     = params[:post_id]
    post = DiscussionPost.find(post_id.to_i)
    @discussion = Discussion.find(discussion_id.to_i)

    has_permission = false
    has_permission = true if (post.user.id == current_user.id)

    if (valid_date && has_permission)
      begin
        ActiveRecord::Base.transaction do
          #Salvando os novos arquivos anexados
          unless params[:attachment].nil?
            params[:attachment].each do |file|
              post_file = DiscussionPostFile.new Hash["attachment", file[1]]
              post_file[:discussion_post_id] = post_id.to_i
              post_file.save!
            end
          end
        end
      rescue Exception => error
        flash[:error] = error.message
      end
    end

    hold_pagination unless @display_mode == "PLAINLIST"

    redirect_to "/discussions/show/" << discussion_id
  end

  #Remoção de arquivo anexo
  def remove_attached_file
    #CHECAR SE A PERMISSAO ESTÁ APENAS PARA O DONO DA POSTAGEM!!!
    @display_mode = params[:display_mode]
    discussion_id = params[:id]
    post_file_id  = params[:idFile]
    file          = DiscussionPostFile.find(post_file_id.to_i)
    @discussion = Discussion.find(discussion_id.to_i)

    #Removendo arquivo da base de dados
    DiscussionPostFile.delete(file.id)

    #Removendo o arquivo do disco
    filename = "#{file.id.to_s}_#{file.attachment_file_name}"
    path = "#{::Rails.root.to_s}/media/discussion/post/#{filename}"
    File.delete(path) if File.exist?(path)

    hold_pagination unless @display_mode == "PLAINLIST"
    redirect_to "/discussions/show/" << discussion_id

  end

  # Posts do aluno
  def show_posts

    # recupera todos os posts do aluno de acordo com o id da discussion enviada
    discussion_id = params[:id]
    student_id = params[:student_id]
    @discussion = Discussion.find(discussion_id)
    @posts = DiscussionPost.all_by_discussion_id_and_student_id(discussion_id, student_id)

    # nao renderiza o layout
    render :layout => false

  end

  private

  def has_no_response
    #DiscussionPost.find_all_by_father_id(discussion_post_id).empty?
    DiscussionPost.find_all_by_father_id(@discussion_post.id).empty?
  end

  def valid_date
    @discussion.start <= Date.today && Date.today <= @discussion.end
  end

  def owned_by_current_user
    current_user.id == @discussion_post.user_id
  end

  def find_allocation_tag_user_profiles(activity_allocation_tag, user)
    query = "SELECT distinct p.* FROM
              allocations al
              inner join profiles p on al.profile_id = p.id
              inner join
              (select
                     root.id as allocation_tag_id,
                     CASE
                       WHEN group_id is not null THEN (select 'GROUP'::text)
                       WHEN offer_id is not null THEN (select 'OFFER'::text)
                       WHEN course_id is not null THEN (select 'COURSE'::text)
                       ELSE (select 'CURRICULUM_UNIT'::text)
                     END as entity_type,
                     (coalesce(group_id, 0) + coalesce(offer_id, 0) +
              coalesce(curriculum_unit_id, 0) + coalesce(course_id, 0)) as entity_id,
                    --parents do tipo offer
                     CASE
                       WHEN group_id is not null THEN (
                         select coalesce(t.id,0)
                         from
                           groups g
                           left join allocation_tags t on t.offer_id = g.offer_id
                         where
                           g.id = root.group_id
                       )
                       ELSE (select 0)
                     END as offer_parent_tag_id,

                     --parents do tipo curriculum unit
                     CASE
                       WHEN group_id is not null THEN (
                         select coalesce(t.id,0)
                         from
                           groups g
                           left join offers o on g.offer_id = o.id
                           left join allocation_tags t on t.curriculum_unit_id = o.curriculum_unit_id
                         where
                           g.id = root.group_id
                       )
                       WHEN offer_id is not null THEN (
                         select coalesce(t.id,0)
                         from
                           offers o
                           left join allocation_tags t on t.curriculum_unit_id = o.curriculum_unit_id
                         where
                           o.id = root.offer_id
                       )
                       ELSE (select 0)
                     END as curriculum_unit_parent_tag_id,

                     --parents do tipo course
                     CASE
                       WHEN group_id is not null THEN (
                         select coalesce(t.id,0)
                         from
                           groups g
                           left join offers o on g.offer_id = o.id
                           left join allocation_tags t on t.course_id = o.course_id
                         where
                           g.id = root.group_id
                       )
                       WHEN offer_id is not null THEN (
                         select coalesce(t.id,0)
                         from
                           offers o
                           left join allocation_tags t on t.course_id = o.course_id
                         where
                           o.id = root.offer_id
                       )
                       ELSE (select 0)
                     END as course_parent_tag_id
              from
                     allocation_tags root
              order by entity_type, allocation_tag_id) as hierarchy
              on
                (al.allocation_tag_id = hierarchy.allocation_tag_id) or
                (al.allocation_tag_id = hierarchy.offer_parent_tag_id) or
                (al.allocation_tag_id = hierarchy.curriculum_unit_parent_tag_id) or
                (al.allocation_tag_id = hierarchy.course_parent_tag_id)
            where
                al.user_id = #{user.id} AND al.status = #{Allocation_Activated} AND
                (
                  (hierarchy.allocation_tag_id = #{activity_allocation_tag.id}) or
                  (hierarchy.offer_parent_tag_id = #{activity_allocation_tag.id}) or
                  (hierarchy.curriculum_unit_parent_tag_id = #{activity_allocation_tag.id}) or
                  (hierarchy.course_parent_tag_id = #{activity_allocation_tag.id})
                )"

    return Profile.find_by_sql(query)
  end

  def find_activity_user_profile_with_permission(activity_allocation_tag, user, controller, action)
    profiles = find_allocation_tag_user_profiles(activity_allocation_tag, user)

    resource_id = Resource.find_by_controller_and_action(controller, action)

    i = 0

    for profile in profiles
      if PermissionsResource.find_by_profile_id_and_resource_id(profile.id, resource_id).nil?
        profiles.remove_at(i)
      end
      i += 1
    end

    for profile in profiles
      if profile.class_responsible
        return profile.id
      end
    end

    if !profiles.empty?
      return profiles[0].id
    end

    return -1
  end
  
end
