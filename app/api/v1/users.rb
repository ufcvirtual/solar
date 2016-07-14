module V1
  class Users < Base

    segment do

      before { guard! }

      namespace :users do

        # GET /users/me
        get "/me", rabl: "users/show" do
          @user = current_user
        end

        # GET /users/1
        get "/:id", rabl: "users/show" do
          @user = User.find(params[:id])
        end

        # GET /users/1/photo
        params do
          optional :style, type: String, values: %w(small forum medium), default: 'medium'
        end
        get "/:id/photo" do
          user = current_user.id == params[:id].to_i ? current_user : User.find(params[:id])
          send_file(user.photo.path(params[:style]))
        end

      end # users

    end # segment

    segment do

      before { verify_ip_access_and_guard! }

      namespace :user do

        params do
          requires :name, :nick, :cpf, :email, type: String
          requires :gender, type: Boolean
          requires :birthdate, type: Date
          optional :username, :cell_phone, :telephone, :address, :address_number, :address_neighborhood, :zipcode, :country, :state, :city, :special_needs, :institution
        end

        post "/" do
          begin
            cpf = params[:cpf].delete('.').delete('-')
            if (user = User.find_by_cpf(cpf)).nil?
              ActiveRecord::Base.transaction do
                new_password = ('0'..'z').to_a.shuffle.first(8).join
                params.merge!(params.include?(:username) ? {password: new_password} : {password: new_password, username: cpf})
                user = User.new user_params(params)
                user.synchronizing = true # ignore MA
                user.save!

                user.update_attribute :password, nil

                Thread.new do
                  Notifier.new_user(user, new_password).deliver
                end
              end
            end
            {id: user.id}
          end
        end # /

        params { requires :cpf, type: String }
        post "import/:cpf" do
          begin
            verify_or_create_user(params[:cpf].delete('.').delete('-'))
            {ok: :ok}
          end
        end

      end # user

      namespace :profiles do

        desc "Retorna usuários com perfis informados"
        params do
          requires :ids, type: String # formato id,id,id
          optional :only_active, type: Boolean, default: true
          # optional :groups_id, type: Array
          optional :semester, type: String
          optional :course_id, :curriculum_unit_id, :curriculum_unit_type_id, :offer_id, :semester_id, type: Integer
          mutually_exclusive :groups_id, :course_id, :curriculum_unit_id, :curriculum_unit_type_id, :offer_id
          mutually_exclusive :groups_id, :offer_id, :semester, :semester_id
        end
        # get "/:ids/users", rabl: "users/index" do
        get "/:ids/:groups_id/users", rabl: "users/index" do
          begin
            query = { allocations: { profile_id: params[:ids].split(',') } }
            allocation_tags_ids = AllocationTag.get_by_params(params, true)[:allocation_tags].compact

            query.merge!({ allocation_tags: { id: allocation_tags_ids } }) unless allocation_tags_ids.blank?
            query[:allocations].merge!({ status: Allocation_Activated }) if params[:only_active]

            @users = User.joins(allocations: :allocation_tag).where(query).uniq
          rescue => error
            log_error(error, code = (allocation_tags_ids.nil? ? 404 : 422))
            error!(error, code)
          end
        end
      end

    end # segment

  end
end
