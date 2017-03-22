include FilesHelper

class PostFilesController < ApplicationController

  doorkeeper_for :api_download

  load_and_authorize_resource :except => [:new, :create, :api_download]
  authorize_resource :only => [:new, :create]

  def new
    @post = Post.find(params[:post_id])
    render :layout => false
  end

  def create
    error = false
    begin
      post       = Post.find(params[:post_id])
      discussion = post.discussion
      can_interact = discussion.user_can_interact?(current_user.id)
      editable = ((post.user_id == current_user.id) && (post.children_count == 0))

      file_names = []
      if ((can_interact) and (post.user_id == current_user.id))
        files = params[:post_file].is_a?(Hash) ? params[:post_file].values : params[:post_file] # {attachment1 => [valores1], attachment2 => [valores2]} => [valores1, valores2]
        [files].flatten.each do |file|
          f = PostFile.create!({ attachment: file, discussion_post_id: post.id })
          file_names << "#{f.id} - #{f.attachment_file_name}"
        end
      else
        raise "not_permited"
      end

      LogAction.create(log_type: LogAction::TYPE[:create], user_id: current_user.id, ip: get_remote_ip, description: "post_file: #{file_names.join(', ')}, post: #{post.id}") rescue nil
    rescue => error
      error = true
    end

    respond_to do |format|
      format.html {
        unless error
          if params.include?('auth_token')
            render :json => {:result => 1}, :status => :created
          else
            render partial: 'posts/file_post', locals:{ post: post, files: post.files, editable: editable, can_interact: can_interact}
          end
        else
          if params.include?('auth_token')
            render :json => {:result => 0}, :status => :unprocessable_entity
          else
            render_json_error(error, 'posts.error.new') 
          end
        end
      }
    end
  end

  def destroy
    error = false
    post  = @post_file.post

    begin
      @post_file.delete
      File.delete(@post_file.attachment.path) if File.exist?(@post_file.attachment.path)
      LogAction.create(log_type: LogAction::TYPE[:destroy], user_id: current_user.id, ip: get_remote_ip, description: "post_file: #{@post_file.id} - #{@post_file.attachment_file_name}, post: #{@post_file.post.id}") rescue nil
    rescue
      error = true
    end

    respond_to do |format|
      unless error
        format.html  { render json: {success: true, notice: t(:updated, :scope => [:posts, :update])}}
        format.json  { render :json => {:result => 1} }
      else
        format.html  { render json: {success: false, :alert => t(:not_updated, :scope => [:posts, :update])}}
        format.json  { render :json => {:result => 0} }
      end
    end
  end

  def download
    redirect_error = posts_path(discussion_id: @post_file.post.discussion.id)
    download_file(redirect_error, @post_file.attachment.path, @post_file.attachment_file_name)
  end

  def api_download
    @post_file = PostFile.find(params[:id])

    redirect_error = posts_path(discussion_id: @post_file.post.discussion.id)
    download_file(redirect_error, @post_file.attachment.path, @post_file.attachment_file_name)
  end

end
