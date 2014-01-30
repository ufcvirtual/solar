module V1
  class Posts < Base

    guard_all!

    namespace :discussions do
      get ":id/posts", rabl: "posts/list" do
        @posts = Discussion.find(params[:id]).posts
      end
    end

    namespace :posts do
      desc "Delete a post."
      params do
        requires :id, type: Integer, desc: "Post ID."
      end
      delete ':id' do
        begin
          current_user.discussion_posts.find(params[:id]).destroy
        rescue
          error!({}, 401)
        end  
      end

      desc "Delete a file of post."
      params do
        requires :id, type: Integer, desc: "File Post ID."
      end

      delete 'files/:id' do
        begin
          if current_user.discussion_post_ids.include?(PostFile.find(params[:id]).discussion_post_id) 
            PostFile.find(params[:id]).destroy 
          else
            raise  
          end 
        rescue 
          error!({}, 401)
        end  
      end

    end
  
  end
end
