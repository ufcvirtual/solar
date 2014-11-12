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
        get "/:id/photo" do
          begin
            user = User.find(params[:id])
            photo = user.photo.path(params[:style] || :small)
            filename = Digest::MD5.hexdigest(user.cpf)

            content_type MIME::Types.type_for(filename)[0].to_s
            env['api.format'] = :binary
            header "Content-Disposition", "attachment; filename*=UTF-8''#{URI.escape(filename)}"

            File.open(photo).read
          rescue
            raise ActiveRecord::RecordNotFound
          end
        end

      end # users

    end # segment

    segment do

      before { verify_ip_access! }

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
                user = User.new params.merge!(params.include?(:username) ? {password: new_password} : {password: new_password, username: cpf})
                user.synchronizing = true # ignore MA
                user.save!

                user.update_attribute :password, nil

                Thread.new do
                  Notifier.new_user(user, new_password).deliver
                end
              end
            end
            {id: user.id}
          rescue => error
            error!({error: error}, 422)
          end
        end # /

        params { requires :cpf, type: String }
        post "import/:cpf" do
          begin
            verify_or_create_user(params[:cpf].delete('.').delete('-'))
            {ok: :ok}
          rescue => error
            error!({error: error}, 422)
          end
        end

      end # user

      namespace :profiles do

        desc "Retorna usuários com perfis informados"
        params do
          requires :ids, type: String # formato id,id,id
          optional :only_active, type: Boolean, default: true
          optional :groups_id, type: Array
          optional :course_id, :curriculum_unit_id, :curriculum_unit_type_id, :offer_id, type: Integer
          mutually_exclusive :groups_id, :course_id, :curriculum_unit_id, :curriculum_unit_type_id, :offer_id
        end
        get "/:ids/users", rabl: "users/index" do
          begin
            query = {allocations: {profile_id: params[:ids].split(",")}}
            allocation_tags_ids = allocation_tags_ids = AllocationTag.get_by_params(params, true)[:allocation_tags].compact
            query.merge!({allocation_tags: {id: allocation_tags_ids}}) unless allocation_tags_ids.blank?
            query[:allocations].merge!({status: Allocation_Activated}) if params[:only_active]

            @users = User.joins(allocations: :allocation_tag).where(query).uniq
          rescue => error
            error!(error, (allocation_tags_ids.nil? ? 404 : 422))
          end
        end
      end

    end # segment

  end
end
