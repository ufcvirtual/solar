include FilesHelper

class PostFilesController < ApplicationController

  #doorkeeper_for :api_download
  before_action :doorkeeper_authorize!, only: [:api_download]

  load_and_authorize_resource except: [:new, :create, :api_download]
  authorize_resource only: [:new, :create]
  before_action :set_current_user, only: [:destroy, :create]

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
      ActiveRecord::Base.transaction do
        if ((can_interact) && (post.user_id == current_user.id))
          files = params[:post_file].is_a?(Hash) ? params[:post_file].values : params[:post_file] # {attachment1 => [valores1], attachment2 => [valores2]} => [valores1, valores2]
          [files].flatten.each do |file|
            f = PostFile.new({ discussion_post_id: post.id, attachment: file })
            f.save!
            file_names << "#{f.id} - #{f.attachment_file_name}"
          end
        elsif (post.user_id != current_user.id)
          raise "permission"
        else
          raise "date_range_expired"
        end

        LogAction.create(log_type: LogAction::TYPE[:create], user_id: current_user.id, ip: get_remote_ip, description: "post_file: #{file_names.join(', ')}, post: #{post.id}") rescue nil
      end
    rescue => error
      error_msg = error
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
            render_json_error(error_msg, 'posts.error', nil, error_msg)
          end
        end
      }
    end
  end

  def destroy
    @post_file.can_change?
    @post_file.verify_children_with_raise

    File.delete(@post_file.attachment.path) if File.exist?(@post_file.attachment.path)
    LogAction.create(log_type: LogAction::TYPE[:destroy], user_id: current_user.id, ip: get_remote_ip, description: "post_file: #{@post_file.id} - #{@post_file.attachment_file_name}, post: #{@post_file.post.id}") rescue nil
    @post_file.delete
    render json: {result: 1}
  rescue => error
    render json: { result: 0, alert: @post_file.errors.full_messages.join('; ') }, status: :unprocessable_entity
  end

  def download
    redirect_error = posts_path(discussion_id: @post_file.post.discussion.id)
    download_file(redirect_error, @post_file.attachment.path, @post_file.attachment_file_name)
  end

  def api_download
    api_guard_with_access_token_or_authenticate
    post_file = PostFile.find(params[:id])

    raise CanCan::AccessDenied unless User.current.allocation_tags_ids_with_access_on(:index, 'posts').include?(post_file.post.academic_allocation.allocation_tag.id)

    begin
      download_file(nil, post_file.attachment.path, post_file.attachment_file_name)
    rescue
      raise 'file not found'
    end
  rescue ActiveRecord::RecordNotFound => error
    Rails.logger.info "[API] [ERROR] [#{Time.now}] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [404] message: #{error}"
    render json: {success: false, status: :not_found, error: error}
  rescue => error
    Rails.logger.info "[API] [ERROR] [#{Time.now}] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [404] message: #{error}"
    render json: {success: false, status: :unprocessable_entity, error: error}
  end

end
