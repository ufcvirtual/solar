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

      namespace :load do

        namespace :user do
          params { requires :cpf }
          # load/user
          post "/" do
            begin
              user = User.new cpf: params[:cpf]
              ma_response = user.connect_and_validates_user
              raise ActiveRecord::RecordNotFound if ma_response.nil? # nao existe no MA
              {ok: :ok}
            rescue => error
              error!({error: error}, 422)
            end
          end
        end # user

      end # load

      namespace :integration do

        namespace :user do
      
          # POST integration/user
          params do
            requires :name, :nick, :birthdate, :gender, :cpf, :email
          end

          post "/" do
            begin
              ActiveRecord::Base.transaction do
                new_password = ('0'..'z').to_a.shuffle.first(8).join
                user = User.new name: params[:name], nick: params[:nick], username: (params.include?(:username) ? params[:username] : params[:cpf]), birthdate: params[:birthdate], gender: params[:gender], 
                  cpf: params[:cpf], email: params[:email], password: new_password, cell_phone: params[:cell_phone], telephone: params[:telephone], special_needs: params[:special_needs], address: params[:address],
                  address_number: params[:address_number], zipcode: params[:zipcode], address_neighborhood: params[:address_neighborhood], country: params[:country], state: params[:state], city: params[:city]
                user.synchronizing = true # ignore MA
                user.save!

                user.update_attribute :password, nil

                Thread.new do
                  Mutex.new.synchronize {
                    Notifier.new_user(user, new_password).deliver
                  }
                end
              end

            rescue => error
              error!({error: error}, 422)
            end

          end # /

        end # user

      end # integration

    end # segment

  end
end
