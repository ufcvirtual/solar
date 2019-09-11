module V1
  class Users < Base

    segment do

      before { guard! }

      namespace :users do

        # GET /users/me
        get "/me", rabl: "users/show" do
          @user = current_user
        end

        # GET /users/1/photo
        params do
          requires :group_id, type: Integer
          optional :style, type: String, values: %w(small forum medium), default: 'medium'
        end
        get "/:id/photo" do

          @group = Group.find(params[:group_id])
          user = User.find(params[:id])

          raise CanCan::AccessDenied if current_user.profiles_with_access_on(:show, :curriculum_units, @group.allocation_tag.related, true).blank?
          raise CanCan::AccessDenied if current_user.id != user.id && user.profiles_with_access_on(:show, :curriculum_units, @group.allocation_tag.related, true).blank?

          if user.photo.path(params[:style]).blank?
            send_file("#{Rails.root}/app/assets/images/no_image_#{params[:style]}.png", params[:style])
          else
            send_file(user.photo.path(params[:style]), params[:style])
          end
        end

      end # users

    end # segment

    segment do

      namespace :user do

        segment do
          before do
            begin
              verify_ip_access!
              @ip = true
            rescue
              guard_client!
              @ip = false
            end
          end

          params do
            requires :name, :cpf, :email, type: String
            requires :gender, type: Boolean
            optional :birthdate, type: Date
            optional :username, :cell_phone, :telephone, :address, :address_number, :address_neighborhood, :zipcode, :country, :state, :city, :special_needs, :institution, :nick
            optional :password
          end

          post "/" do
            begin
              cpf = params[:cpf].delete('.').delete('-')
              cpf = cpf.rjust(11, '0')

              user_exist = User.where(cpf: cpf).first
              user = user_exist.nil? ? User.new(cpf: cpf) : user_exist

              user_data = nil
              if (!User::MODULO_ACADEMICO.nil? && User::MODULO_ACADEMICO['integrated'])
                user_data = User.connect_and_import_user(cpf) # try to import
                user.synchronize(user_data) # synchronize user with new MA data
              end

              new_user = (user.new_record? && !user.integrated)
              raise CanCan::AccessDenied if !new_user && ((!@ip && (user.oauth_application_id.blank? || user.oauth_application_id != @current_client.id)) || (@ip && !user.oauth_application_id.blank?))

              if user_data.blank? || !user.selfregistration
                blacklist = UserBlacklist.where(cpf: user.cpf).first_or_initialize
                blacklist.name = params[:name] if blacklist.new_record?
              end
              can_add_or_exists_blacklist = !blacklist.nil? && (blacklist.valid? || !blacklist.new_record?)

              blacklist.save if blacklist.new_record? && !user.nil? && user.integrated && can_add_or_exists_blacklist && !user.selfregistration

              if new_user || can_add_or_exists_blacklist
                ActiveRecord::Base.transaction do
                  if new_user
                    if params[:password].blank? && @current_client.blank?
                      new_password = ('0'..'z').to_a.shuffle.first(8).join
                      params.merge!({password: new_password})
                    else
                      params.merge!({password: params[:password]})
                    end
                    params.merge!({oauth_application_id: @current_client.try(:id)})
                    params.merge!({nick: params[:name].split(' ').first}) if params[:nick].blank?
                    params[:username].blank? ? params.merge!({username: cpf}) : params.merge!({username: params[:username]})
                  else
                    params.merge!({oauth_application_id: user.oauth_application.try(:id)})
                  end

                  user.attributes = user_params(params)
                  user.valid?

                  if !user.errors[:username].blank?
                    username = user.name.slice(' ') # by name
                    user.username = [username[0].downcase, username[1].downcase].join('_')[0..19] rescue ''
                    user.username = user.email.split('@')[0][0..19] unless user.valid?
                  end

                  user.api = true
                  changes = user.changed - ["password_salt", "oauth_application_id"]

                  user.save!

                  Thread.new do
                    if new_password
                      Notifier.new_user(user, new_password).deliver
                    elsif changes.any? && !new_user
                      user.notify_by_email(changes.include?("username"), changes.include?("encrypted_password"), false, changes)
                    end
                  end
                end
              else # user exists
                log_info('integrated user and cant add to blacklist')
                { id: user.id }
              end

              { id: user.id }
            rescue => error
              log_error(user.errors.full_messages, 422)
              { error: error || user.errors.full_messages.join(', ') }
            end
          end # /


          params do
            requires :cpf, type: String
            optional :gender, type: Boolean
            optional :birthdate, type: Date
            optional :username, :cell_phone, :telephone, :address, :address_number, :address_neighborhood, :zipcode, :country, :state, :city, :special_needs, :institution, :nick, :name, :email, type: String
            optional :password
          end

          put "/:cpf" do
            cpf = params[:cpf].delete('.').delete('-')
            cpf = cpf.rjust(11, '0')

            user = User.where(cpf: cpf).first

            raise ActiveRecord::RecordNotFound if user.blank?
            raise CanCan::AccessDenied if user.oauth_application_id.blank? || user.oauth_application_id != @current_client.id

            user.attributes = user_params(params)
            user.api = true
            changes = user.changed - ["password_salt"]

            user.save

            raise user.errors.full_messages.join(', ') unless user.valid?

            user.notify_by_email(changes.include?("username"), changes.include?("encrypted_password"), false, changes) if changes.any?

            {ok: :ok}
          end
        end #segment

        segment do

          before { verify_ip_access! }

          params do
            requires :cpf, type: String
            optional :only_if_exists, type: Boolean, default: false
          end
          post "import/:cpf" do
            begin
              cpf = params[:cpf].delete('.').delete('-')
              cpf = cpf.rjust(11, '0')
              verify_or_create_user(cpf, false, params[:only_if_exists], true)

              {ok: :ok}
            rescue => error
              raise error
            end
          end

          params do
            requires :cpf, type: String
            requires :name, type: String
          end
          put "unbind/:cpf" do
            begin
              cpf = params[:cpf].delete('.').delete('-')
              cpf = cpf.rjust(11, '0')
              user_blacklist = UserBlacklist.where(cpf: cpf).first_or_initialize
              user_blacklist.name = params[:name] unless params[:name].blank?
              user_blacklist.save!
              {ok: :ok}
            end
          end

          params{requires :cpf, type: String}
          get "verify/:cpf" do
            begin
              cpf = params[:cpf].delete('.').delete('-')
              cpf = cpf.rjust(11, '0')

              user_blacklist = UserBlacklist.where(cpf: cpf).first_or_initialize
              user_blacklist.name = params[:cpf]
              can_add_to_blacklist = (user_blacklist.valid? || !user_blacklist.new_record?)

              {exists_on_blacklist: !user_blacklist.new_record?, can_be_added_to_blacklist: can_add_to_blacklist}
            end
          end

          params do
            requires :cpf, type: String
            optional :username, type: String
            optional :email, type: String
            at_least_one_of :email, :username
          end
          get "validates/:cpf" do
            begin
              cpf = params[:cpf].delete('.').delete('-')
              cpf = cpf.rjust(11, '0')

              error = 0
              user = User.where(cpf: cpf).first
              user = User.new cpf: cpf if user.blank?

              if params[:email].present?
                error = error | 2 if !(!user.new_record? && user.email.try(:downcase) == params[:email].downcase) && User.where("lower(email) = ? AND cpf != ?", params[:email].downcase, cpf).any?
              end

              if params[:username].present?
                if User.where("lower(username) = ? AND cpf != ?", params[:username].downcase, cpf).any?
                  error = error | 4
                elsif (user.username.try(:downcase) != params[:username].downcase)
                  user.username = params[:username].downcase
                  user.synchronizing = true
                  user.valid?
                  error = error | 8 if user.errors[:username].any?
                end
              end

              {result: error}
            end
          end

        end

      end # user

      segment do
        before { guard! }

        namespace :user do
          put :photo do
            current_user.api = true
            current_user.update_attributes!(photo: ActionDispatch::Http::UploadedFile.new(params[:file]))

            {ok: :ok}
          end

          delete :photo do
            current_user.photo = nil
            current_user.api = true
            current_user.save!

            {ok: :ok}
          end

          params do
            optional :style, type: String, values: %w(small forum medium), default: 'medium'
          end
          get :photo do
            if current_user.photo.path(params[:style]).blank?
              send_file("#{Rails.root}/app/assets/images/no_image_#{params[:style]}.png", params[:style])
            else
              send_file(current_user.photo.path(params[:style]), params[:style])
            end
          end
        end
      end

      namespace :profiles do

        segment do

          before { verify_ip_access! }

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
        end #segment
      end # profiles

    end # segment

  end
end
