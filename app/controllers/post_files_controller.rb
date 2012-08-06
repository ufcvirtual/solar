include FilesHelper

class PostFilesController < ApplicationController

  load_and_authorize_resource :except => [:new, :create]

  def new
    authorize! :new, PostFile

    @post = Post.find(params[:post_id])
    render :layout => false
  end

  def create
    authorize! :create, PostFile

    error = false
    begin
      post = Post.find(params[:post_id])
      discussion = post.discussion

      if ((not discussion.closed? or discussion.extra_time?(current_user.id)) and (post.user_id == current_user.id))
        files = params[:post_file].is_a?(Hash) ? params[:post_file].values : params[:post_file]
        [files].flatten.each do |file|
          @file = PostFile.new({ :attachment => file })
          @file.discussion_post_id = post.id
          @file.save!
        end
      else
        raise "not_permited"
      end
    rescue
      error = true
    end

    respond_to do |format|
      format.html {
        unless error
          if params.include?('auth_token')
            render :json => {:result => 1}, :status => :created
          else
            redirect_to(discussion_posts_path(post.discussion), :notice => t(:updated, :scope => [:posts, :update]))
          end
        else
          if params.include?('auth_token')
            render :json => {:result => 0}, :status => :unprocessable_entity
          else
            redirect_to(discussion_posts_path(post.discussion), :alert => t(:not_updated, :scope => [:posts, :update]))
          end
        end
      }
    end
  end

  def destroy
    error = false
    post = @post_file.post

    begin
      @post_file.delete
      File.delete(@post_file.attachment.path) if File.exist?(@post_file.attachment.path)
    rescue
      error = true
    end

    respond_to do |format|
      unless error
        format.html { redirect_to(discussion_posts_path(post.discussion), :notice => t(:updated, :scope => [:posts, :update])) }
        format.xml  { head :ok }
        format.json  { render :json => {:result => 1} }
      else
        format.html { redirect_to(discussion_posts_path(post.discussion), :alert => t(:not_updated, :scope => [:posts, :update])) }
        format.xml  { head :error }
        format.json  { render :json => {:result => 0} }
      end
    end
  end

  def download
    post = @post_file.post
    download_file(discussion_posts_path(post.discussion), @post_file.attachment.path, @post_file.attachment_file_name)
  end

end
