class DiscussionsController < ApplicationController

  include DiscussionPostsHelper

  load_and_authorize_resource :except => [:list, :attach_file, :download_post_file, :remove_attached_file, :show_posts, :post_file_upload] #Setar permissoes!!!!!

  before_filter :prepare_for_pagination

  def list

    authorize! :list, Discussion

    # pegando dados da sessao e nao da url
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    offer_id = session[:opened_tabs][session[:active_tab]]["offers_id"]

    group_id = -1 if group_id.nil?
    offer_id = -1 if offer_id.nil?

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
    plain_list = (@display_mode == "PLAINLIST")

    @posts = DiscussionPost.discussion_posts(@discussion.id, plain_list, @current_page)
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
    has_permission = true if profile_id > 0

    #Usuário só pode criar posts no período ativo do fórum
    if (valid_date && has_permission)
      begin
        ActiveRecord::Base.transaction do
          #Criando nova postagem
          new_discussion_post = DiscussionPost.new :discussion_id => discussion_id,
            :user_id => current_user.id,
            :profile_id => profile_id,
            :content => content, :father_id => parent_id
          new_discussion_post.save!
        end
      rescue Exception => error
        flash[:error] = error.message
      end

      #Se a exibição for do tipo PLAINLIST, a nova postagem aparece no inicio, logo, não devemos manter a página atual
      hold_pagination unless (@display_mode == "PLAINLIST" or parent_id == "")

    end

    redirect_to "/discussions/show/#{discussion_id}"
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
      if (owned_by_current_user && valid_date && has_no_response)

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
          flash[:error] = t(:forum_remove_error)
        end

      end
    end

    hold_pagination
    redirect_to "/discussions/show/#{discussion_id}"
  end

  def update_post
    discussion_id = params[:discussion_id]
    discussion_post_id = params[:discussion_post_id]
    new_content = params[:content]

    #(# Só o dono do post pode editar, se estiver no período ativo do fórum e se a postagem não tiver resposta(filhos))
    @discussion_post= DiscussionPost.find_by_id(discussion_post_id)
    @discussion= Discussion.find_by_id(discussion_id)

    if (owned_by_current_user && valid_date && has_no_response)
      post = DiscussionPost.find(discussion_post_id);
      post.update_attributes({:content => new_content})
    end

    hold_pagination
    redirect_to "/discussions/show/#{discussion_id}"
  end

  #Formulário de upload exibido numa lightbox
  def post_file_upload
    render :layout => false
  end

  #Download de arquivo anexo
  def download_post_file
    post_file_id = params[:idFile]
    file_ = DiscussionPostFile.find(post_file_id)
    #filename = file_.attachment_file_name
    filename = ''

    prefix_file = nil

    path_file = file_.attachment.path

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

    has_permission = (post.user.id == current_user.id)

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

    redirect_to "/discussions/show/#{discussion_id}"
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
    path = "#{::Rails.root.to_s}/media/discussions/post/#{filename}"
    File.delete(path) if File.exist?(path)

    hold_pagination unless @display_mode == "PLAINLIST"
    redirect_to "/discussions/show/#{discussion_id}"

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
    DiscussionPost.find_all_by_father_id(@discussion_post.id).empty?
  end

  def owned_by_current_user
    current_user.id == @discussion_post.user_id
  end

  def find_activity_user_profile_with_permission(activity_allocation_tag, user, controller, action)

    # Todos os perfis do usuario nesta allocation_tag
    profiles = Profile.find_by_allocation_tag_and_user_id(activity_allocation_tag.id, user.id)

    # recupera id do resource
    resource_id = Resource.find_by_controller_and_action(controller, action)

    # separando apenas os perfis que tem permissao de acessar a funcionalidade
    profiles.each_with_index do |profile, idx|
      if PermissionsResource.find_by_profile_id_and_resource_id(profile.id, resource_id).nil?
        profiles.remove_at(idx)
      end
    end

    # retorna o primeiro perfil responsavel se existir
    profiles.each do |profile|
      return profile.id if profile.class_responsible
    end

    # retorna o primeiro perfil encontrado
    return profiles.first.id unless profiles.empty?

    # nenhum perfil com permissao de acesso
    return -1

  end

end
