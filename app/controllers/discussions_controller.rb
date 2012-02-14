class DiscussionsController < ApplicationController

  include FilesHelper
  include DiscussionPostsHelper

  load_and_authorize_resource :except => [:list, :show_posts] #Setar permissoes!!!!!

  before_filter :prepare_for_pagination
  before_filter :prepare_for_group_selection, :only => [:list]

  def list
    authorize! :list, Discussion

    allocation_tag_id = active_tab[:url]['allocation_tag_id']
    allocations = AllocationTag.find_related_ids(allocation_tag_id)
    @discussions = Discussion.all_by_allocations(allocations.join(','))

  end

  def show
    allocation_tag = AllocationTag.find(active_tab[:url]['allocation_tag_id'])

    group_id = allocation_tag.group_id
    offer_id = allocation_tag.offer_id

    discussion_id = params[:discussion_id]
    discussion_id = params[:id] if discussion_id.nil?
    @display_mode = params[:display_mode]

    unless(permitted_discussions(offer_id, group_id, discussion_id).empty?)
      if @display_mode.nil?
        @display_mode = session[:forum_display_mode]
      else
        session[:forum_display_mode] = @display_mode
      end

      @discussion = Discussion.find(discussion_id)
      plain_list = (@display_mode == "PLAINLIST")

      @posts = DiscussionPost.discussion_posts(@discussion.id, plain_list, @current_page)
    else
      redirect_to :controller => :discussions, :action => :list # "/discussions/list"
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
    has_permission = true if profile_id > 0

    #Usuário só pode criar posts no período ativo do fórum
    if (valid_date && has_permission)
      begin
        ActiveRecord::Base.transaction do
          #Criando nova postagem
          new_discussion_post = DiscussionPost.new :discussion_id => discussion_id,
            :user_id => current_user.id,
            :profile_id => profile_id,
            :content => content,
            :parent_id => parent_id
          new_discussion_post.save!
        end
      rescue Exception => error
        flash[:error] = error.message
      end

      #Se a exibição for do tipo PLAINLIST, a nova postagem aparece no inicio, logo, não devemos manter a página atual
      hold_pagination unless (@display_mode == "PLAINLIST" or parent_id == "")
    end

    redirect_to :controller => :discussions, :action => :show, :id => discussion_id # "/discussions/show/#{discussion_id}"
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
            path = "#{::Rails.root.to_s}/media/discussions/post/#{filename}"
            File.delete(path) if File.exist?(path)
          end
        else
          flash[:error] = t(:forum_remove_error)
        end

      end
    end

    hold_pagination
    redirect_to :controller => :discussions, :action => :show, :id => discussion_id # "/discussions/show/#{discussion_id}"
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
    redirect_to :controller => discussions, :action => :show, :id => discussion_id # "/discussions/show/#{discussion_id}"
  end

  #Formulário de upload exibido numa lightbox
  def post_file_upload
    render :layout => false
  end

  ##
  # Download de arquivo anexo a postagem
  ##
  def download_post_file
    post_file_id = params[:idFile]
    download_file({:action => :show, :id => params[:id], :idFile => post_file_id}, DiscussionPostFile.find(post_file_id).attachment.path)
  end

  #Envio de arquivo anexo
  def attach_file

    @display_mode = params[:display_mode]
    discussion_id = params[:id]
    post_id     = params[:post_id]
    post = DiscussionPost.find(post_id.to_i)
    @discussion = Discussion.find(discussion_id.to_i)

    owned_by_current_user = (post.user.id == current_user.id)
    has_no_response = DiscussionPost.find_all_by_parent_id(post_id).empty?

    if (owned_by_current_user&& valid_date && has_no_response)
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

    redirect_to :controller => :discussions, :action => :show, :id => discussion_id # "/discussions/show/#{discussion_id}"
  end

  #Remoção de arquivo anexo
  def remove_attached_file
    @display_mode = params[:display_mode]
    discussion_id = params[:id]
    post_file_id  = params[:idFile]
    file          = DiscussionPostFile.find(post_file_id.to_i)
    @discussion = Discussion.find(discussion_id.to_i)

    post = file.discussion_post

    owned_by_current_user = (post.user.id == current_user.id)
    has_no_response = DiscussionPost.find_all_by_parent_id(post.id).empty?

    if (owned_by_current_user && valid_date && has_no_response)
      #Removendo arquivo da base de dados
      DiscussionPostFile.delete(file.id)

      #Removendo o arquivo do disco
      filename = "#{file.id.to_s}_#{file.attachment_file_name}"
      path = "#{::Rails.root.to_s}/media/discussions/post/#{filename}"
      File.delete(path) if File.exist?(path)

      hold_pagination unless @display_mode == "PLAINLIST"
    end

    redirect_to :controller => :discussions, :action => :show, :id => discussion_id # "/discussions/show/#{discussion_id}"

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
    DiscussionPost.find_all_by_parent_id(@discussion_post.id).empty?
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
    profiles.delete_if {|profile| PermissionsResource.find_by_profile_id_and_resource_id(profile.id, resource_id).nil?}

    # retorna o primeiro perfil responsavel se existir
    profiles.each do |profile|
      return profile.id if (profile.types & Profile_Type_Class_Responsible) == Profile_Type_Class_Responsible
    end

    # retorna o primeiro perfil encontrado
    return profiles.first.id unless profiles.empty?

    # nenhum perfil com permissao de acesso
    return -1

  end

end