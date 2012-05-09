include FilesHelper

class PostFilesController < ApplicationController

  def new
    @post = Post.find(params[:post_id])
    render :layout => false
  end

  def create
    post = Post.find(params[:post_id])
    discussion_closed = Discussion.find(post.discussion_id).closed?
    error = false
    begin
      if ((not discussion_closed) and (post.user_id == current_user.id))
        params[:post_file].each do |file|
          @file = PostFile.new({:attachment => file.last})
          @file.discussion_post_id = post.id
          @file.save!
        end
      end
    rescue
      error = true
    end

    respond_to do |format|
      unless error
        format.html { redirect_to(discussion_posts_path(post.discussion), :notice => t(:discussion_post_updated)) }
        format.json  { render :json => {:result => 1} }
      else
        format.html { redirect_to(discussion_posts_path(post.discussion), :alert => t(:discussion_post_not_updated)) }
        format.json  { render :json => {:result => 0} }
      end
    end
  end

  def destroy
    file = PostFile.find(params[:id])
    post = file.post
    error = false

    if post.user_id == current_user.id and post.id == params[:post_id].to_i
      file.delete
      File.delete(file.attachment.path) if File.exist?(file.attachment.path)
    else
      error = true
    end

    respond_to do |format|
      unless error
        format.html { redirect_to(discussion_posts_path(post.discussion), :notice => t(:discussion_post_updated)) }
        format.xml  { head :ok }
        format.json  { render :json => {:result => 1} }
      else
        format.html { redirect_to(discussion_posts_path(post.discussion), :alert => t(:discussion_post_not_updated)) }
        format.xml  { head :error }
        format.json  { render :json => {:result => 0} }
      end
    end
  end

  def download
    file = PostFile.find(params[:id])
    post = file.post
    download_file(discussion_posts_path(post.discussion), file.attachment.path, file.attachment_file_name)
  end

end
