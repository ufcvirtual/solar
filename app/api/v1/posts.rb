module V1
  class Posts < Base

    guard_all!

    namespace :discussions do
  
      helpers do
        # return a @discussion object
        def verify_user_permission_on_discussion_and_set_obj(permission) # permission = [:index, :create, ...]
          @discussion = Discussion.find(params[:id])
          @profile_id  = current_user.profiles_with_access_on(permission, :posts, @discussion.academic_allocations.map(&:allocation_tag).map(&:related), true).first
          discussion_group_ids = @discussion.group_ids + @discussion.offers.includes(:groups).map(&:group_ids).flatten

          raise ActiveRecord::RecordNotFound if @profile_id.nil? or (discussion_group_ids & current_user.groups(@profile_id, Allocation_Activated).map(&:id)).empty?
        end
      end

      ## NEW and HISTORY

      segment do
        before do
          verify_user_permission_on_discussion_and_set_obj(:index)
        end # before

        after do
          filtered_params = params.select { |k, v| ["date", "order", "limit", "display_mode", "type"].include?(k) }
          @posts = @discussion.posts(filtered_params)

          @period = if @posts.empty?
            ["#{filtered_params['date'] || DateTime.now}", "#{filtered_params['date'] || DateTime.now}"]
          else
            newer_post_date, older_post_date = @posts.first.updated_at, @posts.last.updated_at
            ["#{older_post_date}", "#{newer_post_date}"]
          end
        end # after

        params do # parâmetros comuns às duas chamadas: new e history
          optional :order, type: String, values: %w(asc desc), default: "desc", desc: "Posts order."
          optional :limit, type: Integer, desc: "Posts limit."
          optional :display_mode, type: String, values: %w(list tree), default: "list", desc: "Posts display mode."
        end

        desc "Lista dos posts mais novos. Se uma data for passada, aqueles serão a partir dela."
        params { optional :date, type: DateTime, desc: "Posts date." }
        get ":id/posts/new", rabl: "posts/list_with_counting" do
          params[:type] = "new"
          # @posts
        end

        desc "Lista dos posts mais antigos com relação a uma data."
        params { requires :date, type: DateTime, desc: "Posts date." }
        get ":id/posts/history", rabl: "posts/list_with_counting" do
          params[:type] = "history"
          # @posts
        end
      end # segment

      ## CREATE

      params do
        requires :id, type: Integer, desc: "Discussion ID."
      end
      post ":id/posts" do
        verify_user_permission_on_discussion_and_set_obj(:create)

        raise MissingTokenError unless @discussion.user_can_interact?(current_user.id) # unauthorized

        @post = @discussion.posts.build(params[:post])
        @post.user = current_user         
        @post.level = @post.parent.level.to_i + 1 unless @post.parent_id.nil?
        @post.profile_id = @profile_id

        if @post.save
          { id: @post.id }
        else
          error!(@post.errors.full_messages, 422)
        end
      end #:id/posts

    end # namespace discussions

    namespace :posts do

      ## CREATE files

      desc "Send files to a post."
      params do
        requires :id, type: Integer, desc: "Post ID."
      end
      post ':id/files' do
        post = Post.find(params[:id])

        raise ActiveRecord::RecordNotFound if (post.user_id != current_user.id)
        error!({}, 401) unless post.discussion.user_can_interact?(current_user.id)

        ids = []
        [params[:file]].flatten.each do |file|
          post_attachment = post.files.build(attachment: ActionDispatch::Http::UploadedFile.new(file))
          ids << post_attachment.id if post_attachment.save
        end # each

        { ids: ids }
      end

      ## LIST files

      # GET posts/:id/files
      desc "Files of a post."
      params do
        requires :id, type: Integer, desc: "Discussion ID."
      end
      get ":id/files", rabl: "posts/files" do
        raise ActiveRecord::RecordNotFound unless current_user.discussion_post_ids.include?(params[:id]) # user is owner
        @files = Post.find(params[:id]).files
      end

      ## DELETE post and files

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
  end # namespace posts
end
