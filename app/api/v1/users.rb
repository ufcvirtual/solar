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
            user = User.find_by_cpf(cpf)
            user.synchronize if user.can_synchronize?

            blacklist = UserBlacklist.where(cpf: cpf).first_or_initialize
            blacklist.name = params[:name] if blacklist.new_record?
            can_add_or_exists_blacklist = blacklist.valid? || !blacklist.new_record?
            blacklist.save if blacklist.new_record? && !user.nil? && user.integrated && can_add_or_exists_blacklist

            if user.nil? || can_add_or_exists_blacklist
              ActiveRecord::Base.transaction do
                if user.nil?
                  new_password = ('0'..'z').to_a.shuffle.first(8).join
                  params.merge!({password: new_password}) 
                end
                params.merge!({username: cpf}) if params[:username].blank? && user.nil?
                if user.nil?
                  user = User.new user_params(params)
                else
                  user.attributes = user_params(params)
                end
                user.valid?
                if !user.errors[:username].blank?
                  username = user.name.slice(' ') # by name
                  user.username = [username[0].downcase, username[1].downcase].join('_')[0..19] rescue ''
                  user.username = user.email.split('@')[0][0..19] unless user.valid?
                end

                user.save!

                Thread.new do
                  if new_password
                    Notifier.new_user(user, new_password).deliver
                  else
                    user.notify_by_email
                  end
                end
              end
            else # user exists
              log_info('integrated user and cant add to blacklist')
              { id: user.id }
            end
            { id: user.id }
          rescue
            log_error(user.errors.full_messages, 422)
          end
        end # /

        params { requires :cpf, type: String }
        post "import/:cpf" do
          begin
            verify_or_create_user(params[:cpf].delete('.').delete('-'))
            {ok: :ok}
          end
        end

        params do
          requires :cpf, type: String
          requires :name, type: String
        end
        put "unbind/:cpf" do
          begin
            user_blacklist = UserBlacklist.where(cpf: params[:cpf].delete('.').delete('-')).first_or_initialize
            user_blacklist.name = params[:name] unless params[:name].blank?
            user_blacklist.save!
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
