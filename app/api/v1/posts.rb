module V1
  class Posts < Base

    guard_all!

    namespace :discussions do
      get ":id/posts", rabl: "posts/list" do
        @posts = Discussion.find(params[:id]).posts
      end
    end

    namespace :posts do

      ## CREATE

      desc "Criar uma nova postagem"
      post do
        # ainda nao feito ==> apenas para teste
        Post.first.id
      end

      ## LIST

      desc "Lista de arquivos do post"
      params do
        requires :id, type: Integer, desc: "Discussion ID."
      end
      get ":id/files", rabl: "posts/files" do
        raise ActiveRecord::RecordNotFound unless current_user.discussion_post_ids.include?(params[:id]) # user is owner
        @files = Post.find(params[:id]).files
      end

      ## DELETE

      desc "Delete a post."
      params do
        requires :id, type: Integer, desc: "Post ID."
      end
      delete ':id' do
        current_user.discussion_posts.find(params[:id]).destroy # user posts
      end

      desc "Delete a file of a post."
      params do
        requires :id, type: Integer, desc: "File Post ID."
      end
      delete 'files/:id' do
        pfile = PostFile.find(params[:id])

        raise ActiveRecord::RecordNotFound unless current_user.discussion_post_ids.include?(pfile.discussion_post_id) # user files
        pfile.destroy
      end

    end

  end
end
