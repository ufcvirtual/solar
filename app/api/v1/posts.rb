module V1
  class Posts < Base

    guard_all!

    namespace :discussions do

      helpers do
        # return a @discussion object
        def verify_user_permission_on_discussion_and_set_obj(permission) # permission = [:index, :create, ...]
          raise 'exam' if Exam.verify_blocking_content(current_user.id) || false

          @discussion = Discussion.find(params[:id])
          @group      = Group.find(params[:group_id])
          @profile_id = current_user.profiles_with_access_on(permission, :posts, @group.allocation_tag.related, true).first

          raise CanCan::AccessDenied if @profile_id.nil? || !(current_user.groups([@profile_id], Allocation_Activated).include?(@group))
        end

        def post_params
          ActionController::Parameters.new(params).require(:discussion_post).permit(:content, :parent_id, :draft)
        end
      end

      ## NEW and HISTORY (deprecated)

      segment do
        before do
          verify_user_permission_on_discussion_and_set_obj(:index)
        end # before

        after do
          filtered_params = params.select { |k, v| ['date', 'order', 'limit', 'display_mode', 'type'].include?(k) }
          @ats   = [@group.allocation_tag.id]
          @posts = @discussion.posts(filtered_params, @ats)

          @period = if @posts.empty?
            ["#{filtered_params['date'] || DateTime.now.to_s(:db)}", "#{filtered_params['date'] || DateTime.now.to_s(:db)}"]
          else
            newer_post_date, older_post_date = @posts.first.updated_at.to_s(:db), @posts.last.updated_at.to_date.to_s(:db)
            ["#{older_post_date}", "#{newer_post_date}"]
          end
        end # after

        desc 'Lista dos posts mais novos. Se uma data for passada, aqueles serão a partir dela.'
        params do # parâmetros comuns às duas chamadas: new e history
          requires :group_id, type: Integer, desc: 'Group ID.'
          optional :date, type: DateTime, desc: 'Posts date.'

          optional :order, type: String, values: %w(asc desc), default: 'desc', desc: 'Posts order.'
          optional :limit, type: Integer, desc: 'Posts limit.'
          optional :display_mode, type: String, values: %w(list tree), default: 'list', desc: 'Posts display mode.'
        end
        get ':id/posts/new', rabl: 'posts/list_with_counting' do
          params[:type] = "new"
          # @posts
        end

        desc 'Lista dos posts mais antigos com relação a uma data.'
        params do # parâmetros comuns às duas chamadas: new e history
          requires :group_id, type: Integer, desc: 'Group ID.'
          requires :date, type: DateTime, desc: 'Posts date.'

          optional :order, type: String, values: %w(asc desc), default: 'desc', desc: 'Posts order.'
          optional :limit, type: Integer, desc: 'Posts limit.'
          optional :display_mode, type: String, values: %w(list tree), default: 'list', desc: 'Posts display mode.'
        end
        get ':id/posts/history', rabl: 'posts/list_with_counting' do
          params[:type] = "history"
          # @posts
        end
      end # segment

      ## first level and children

      segment do
        before do
          verify_user_permission_on_discussion_and_set_obj(:index)
        end # before

        ## discussions/1/posts
        desc 'Lista de posts de primeiro nivel.'
        params do
          requires :id, type: Integer, desc: 'Discussion ID.'
          requires :group_id, type: Integer, desc: 'Group ID.'
          optional :limit, type: Integer, desc: 'Posts limit.', default: Rails.application.config.items_per_page.to_i
          optional :page, type: Integer, desc: 'Page.', default: 1
          optional :ignore_drafts, type: Boolean, default: true
        end
        get ':id/posts', rabl: 'posts/list' do
          offset = (params['page'].to_i * params['limit'].to_i) - params['limit'].to_i
          allocation_tags_ids = @group.allocation_tag.related
          query = params[:ignore_drafts] ? '' : " OR (discussion_posts.draft = 't' AND discussion_posts.user_id = #{current_user.id})"
          @posts = @discussion.discussion_posts.select('discussion_posts.*, count(children.id) AS children_count')
                        .joins(academic_allocation: :allocation_tag)
                        .joins('LEFT JOIN discussion_posts AS children ON children.parent_id = discussion_posts.id')
                        .where('discussion_posts.parent_id IS NULL')
                        .where(allocation_tags: { id: allocation_tags_ids })
                        .where("discussion_posts.draft = 'f' #{query}")
                        .group('discussion_posts.id')
                        .order('discussion_posts.updated_at asc')
                        .limit(params[:limit])
                        .offset(offset)
        end

        ## discussions/1/posts
        desc 'Lista de posts filhos.'
        params do
          requires :id, type: Integer, desc: 'Post ID.'
          optional :limit, type: Integer, default: Rails.application.config.items_per_page.to_i, desc: 'Posts limit.'
          optional :page, type: Integer, default: 1, desc: 'Page.'
          optional :ignore_drafts, type: Boolean, default: true
        end
        get ':id/posts/:post_id/children', rabl: 'posts/list' do
          offset = (params['page'].to_i * params['limit'].to_i) - params['limit'].to_i
          query = params[:ignore_drafts] ? '' : " OR (discussion_posts.draft = 't' AND discussion_posts.user_id = #{current_user.id})"
          @posts = Post.select('discussion_posts.*, count(children.id) AS children_count')
              .joins('LEFT JOIN discussion_posts AS children ON children.parent_id = discussion_posts.id')
              .group('discussion_posts.id')
              .where(parent_id: params[:post_id])
              .where("discussion_posts.draft = 'f' #{query}")
              .limit(params[:limit])
              .offset(offset)
        end
      end

      ## CREATE

      params do
        requires :id, type: Integer, desc: 'Discussion ID.'
        requires :discussion_post, type: Hash do
          requires :content, type: String
          optional :parent_id, type: Integer
          optional :draft, type: Boolean, default: false
        end
      end
      post ":id/posts" do
        verify_user_permission_on_discussion_and_set_obj(:create)

        raise MissingTokenError unless @discussion.user_can_interact?(current_user.id) # unauthorized

        ats = [AllocationTag.find_by_group_id(@group.id)] || RelatedTaggable.related({ group_id: @group.id })

        academic_allocation = @discussion.academic_allocations.where(allocation_tag_id: ats).first

        acu = AcademicAllocationUser.find_or_create_one(academic_allocation.id, ats.first, current_user.id, nil, true, nil)

        @post = Post.new(post_params)
        @post.content = CGI::escapeHTML(@post.content)
        @post.user = current_user
        @post.profile_id = @profile_id
        @post.academic_allocation_id = academic_allocation.id
        @post.academic_allocation_user_id = acu.try(:id)
        @post.api = true
        User.current = current_user

        if @post.save
          { id: @post.id }
        else
          raise @post.errors.full_messages.join(', ')
        end
      end #:id/posts

      namespace :post do
        desc 'Update a post.'
        params do
          requires :id, type: Integer, desc: 'Post ID.'
          requires :discussion_post, type: Hash do
            optional :content, type: String
            optional :draft, type: Boolean
            at_least_one_of :content, :draft
          end
        end
        put ':id' do
          User.current = current_user
          raise 'exam' if Exam.verify_blocking_content(current_user.id) || false

          post = Post.find(params[:id])

          raise ActiveRecord::RecordNotFound if post.blank?
          raise CanCan::AccessDenied if (post.user_id != current_user.id)
          raise CanCan::AccessDenied unless post.discussion.user_can_interact?(current_user.id)

          post_params[:content] = CGI::escapeHTML(post_params[:content]) unless post_params[:content].blank?
          post.api = true

          if post.update_attributes post_params
            { id: post.id }
          else
            raise post.errors.full_messages.join(', ')
          end
        end
      end # namespace post
    end # namespace discussions


    namespace :posts do

      ## CREATE files

      desc 'Send files to a post.'
      params { requires :id, type: Integer, desc: 'Post ID.' }
      post ':id/files' do
        post = Post.find(params[:id])

        raise ActiveRecord::RecordNotFound if (post.user_id != current_user.id)
        raise CanCan::AccessDenied unless post.discussion.user_can_interact?(current_user.id)
        User.current = current_user

        ids = []
        [params[:file]].flatten.each do |file|
          post_attachment = PostFile.new({ discussion_post_id: post.id, attachment: ActionDispatch::Http::UploadedFile.new(file) })
          post_attachment.api = true
          # post_attachment = post.files.build(attachment: ActionDispatch::Http::UploadedFile.new(file))
          ids << post_attachment.id if post_attachment.save
        end # each

        { ids: ids }
      end

      ## LIST files

      # GET posts/:id/files
      desc 'Files of a post.'
      params { requires :id, type: Integer, desc: 'Discussion ID.' }
      get ":id/files", rabl: "posts/files" do
        raise 'exam' if Exam.verify_blocking_content(current_user.id) || false
        raise ActiveRecord::RecordNotFound unless current_user.discussion_post_ids.include?(params[:id]) # user is owner
        @files = Post.find(params[:id]).files
      end

      ## DELETE post and files

      desc 'Delete a post.'
      params { requires :id, type: Integer, desc: 'Post ID.' }
      delete ':id' do
        User.current = current_user
        raise 'exam' if Exam.verify_blocking_content(current_user.id) || false
        user_posts = current_user.discussion_posts.find(params[:id])
        user_posts.api = true
        user_posts.destroy # user posts
      end

      desc 'Delete a file of a post.'
      params { requires :id, type: Integer, desc: 'File Post ID.' }
      delete 'files/:id' do
        pfile = PostFile.find(params[:id])
        User.current = current_user
        raise 'exam' if Exam.verify_blocking_content(current_user.id) || false
        raise ActiveRecord::RecordNotFound unless current_user.discussion_post_ids.include?(pfile.discussion_post_id) # user files
        pfile.api = true
        pfile.destroy
      end

    end # namespace posts

  end
end
