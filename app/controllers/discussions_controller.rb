class DiscussionsController < ApplicationController

  include DiscussionPostsHelper

  load_and_authorize_resource #Setar permissoes!!!!!
  before_filter :prepare_for_pagination, :only => [:show]
  
  def list

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
    load_posts 
  end

  def new_post
    discussion_id = params[:discussion_id]
    content       = params[:content]
    parent_id     = params[:parent_post_id]
    #DEFINIR O PROFILE!!!! 
    #profile_id    = 2
    profile_id    = 1 #DEFINIR O PROFILE!!!! ##################################################
    
   
    @discussion= Discussion.find_by_id(discussion_id)
    
    #Usuário só pode criar posts no período ativo do fórum
    if (valid_date)
      begin
        ActiveRecord::Base.transaction do
          #Criando nova postagem
          new_discussion_post = DiscussionPost.new :discussion_id => discussion_id, :user_id => current_user.id, :profile_id => profile_id, :content => content, :father_id => parent_id
          new_discussion_post.save!

          #Salvando os arquivos anexados à postagem
          unless params[:attachment].nil?
            params[:attachment].each do |file|
              post_file = DiscussionPostFile.new Hash["attachment", file[1]]
              post_file[:discussion_post_id] = new_discussion_post.id
              post_file.save!
            end
          end
        end
      rescue Exception => error
        flash[:error] = error.message
      end

      #Se a exibição for do tipo PLAINLIST, a nova postagem aparece no inicio, logo, não devemos manter a página atual
      if @display_mode != "PLAINLIST"
        hold_pagination
      end
    
    end   

    redirect_to "/discussions/show/" << discussion_id
  end

  def remove_post
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

      hold_pagination
    end
    redirect_to "/discussions/show/" << discussion_id
  end

  # download dos arquivos da postagem
  def download_post_file
    post_file_id = params[:idFile]
    file_ = DiscussionPostFile.find(post_file_id)
    filename = file_.attachment_file_name

    prefix_file = file_.id # id da tabela discussion_post_file para diferenciar os arquivos
    path_file = "#{::Rails.root.to_s}/media/discussion/post/"

    # id da atividade
    #send_assignment = SendAssignment.joins(:assignment_comments).where(["assignment_comments.id = ?", assignment_comment_id])

    # verifica se foi encontrado algum registro
    #if send_assignment.length > 0
    #  assignment_id = send_assignment.first.assignment_id
    #  redirect_error = {:action => 'activity_details', :id => assignment_id}
    #else

    #  curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]
    # redireciona para a pagina de listagem de atividades
    #  redirect_error = {:action => 'list', :id => curriculum_unit_id}

    #end
    redirect_error = {:action => 'show', :id => params[:id], :idFile => post_file_id}
    # recupera arquivo
    
    download_file(redirect_error, path_file, filename, prefix_file)

  end

  private
  def load_posts
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
      @posts = return_discussion_posts(@discussion.id, true)
    else
      @posts = return_discussion_posts(@discussion.id, false)
    end
  end

  def has_no_response
    DiscussionPost.find_all_by_father_id(@discussion_post.id).empty?
  end

  def valid_date
    @discussion.start <= Date.today && Date.today <= @discussion.end
  end

  def owned_by_current_user
    current_user.id == @discussion_post.user_id
  end
  
end
