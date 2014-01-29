module V1
  class Posts < Base

    # guard_all!

    namespace :discussions do
      get ":id/posts", rabl: "posts/list" do
        @posts = Discussion.find(params[:id]).posts
      end
    end

  end
end
