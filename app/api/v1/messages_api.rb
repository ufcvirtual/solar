module V1
  class MessagesAPI < Base

    guard_all!

    namespace :message do

      segment do

        desc 'Exibir mensagem', {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        get "/:id", rabl: 'messages/show' do
          @message = Message.find(params[:id])

          sent_by_responsible = @message.allocation_tag.is_responsible?(@message.sent_by.id) unless @message.allocation_tag_id.blank?
          read_message(@message)
          LogAction.create(log_type: LogAction::TYPE[:update], user_id: current_user.id, ip: get_remote_ip, description: "message: #{@message.id} read message from #{sent_by_responsible ? 'responsible' : 'other'}", allocation_tag_id: @message.allocation_tag_id) rescue nil
        end

        desc 'Compor Mensagem', {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          requires :group_id, type: Integer
          optional :files, type: Array
          requires :message, type: Hash do
            requires :content, type: String
            requires :subject, type: String
            requires :contacts, type: String
          end
        end
        post '/' do
          ActiveRecord::Base.transaction do
            raise 'group mandatory' if params[:group_id].blank?
            @group = Group.find(params[:group_id])

            raise CanCan::AccessDenied if current_user.profiles_with_access_on(:index, :messages, @group.allocation_tag.related, true).blank? # unauthorized
            raise 'content mandatory' if params[:message][:content].blank?
            raise 'subject mandatory' if params[:message][:subject].blank?
            raise 'contacts mandatory' if params[:message][:contacts].blank?

            @message = Message.new(params[:message])
            @message.sender = current_user
            @message.allocation_tag_id = @group.allocation_tag.id
            @message.api = true

            unless params[:files].blank?
              [params[:files]].flatten.each do |file|
                @message.files.new({ attachment: ActionDispatch::Http::UploadedFile.new(file) })
              end # each
            end

            emails = []
            unless params[:message][:contacts].nil?
              emails = User.joins('LEFT JOIN personal_configurations AS nmail ON users.id = nmail.user_id')
                            .where("(nmail.message IS NULL OR nmail.message=TRUE)")
                            .where(id: params[:message][:contacts].split(',')).pluck(:email).flatten.compact.uniq
            end

            if @message.save
              Job.send_mass_email(emails, @message.subject, new_msg_template(@group.allocation_tag, @message), @message.files.to_a, current_user.email)

              { id: @message.id }
            else
              raise @message.errors.full_messages
            end
          end # transaction

        end #end post
      end #segment

      helpers do
        # return a @message object
        def verify_user_permission_and_set_obj(permission) # permission = [:index, :create, ...]
          @group = params[:group_id].blank? ? nil : Group.find(params[:group_id])
          @allocation_tag_related = @group.nil? ? nil : @group.allocation_tag.related
          @profile_id = current_user.profiles_with_access_on(permission, :messages, @allocation_tag_related, true).first
          raise CanCan::AccessDenied if @profile_id.nil? || current_user.groups([@profile_id], Allocation_Activated).blank?
        end

        def option_user_box(type)
          return type if ['outbox', 'trashbox'].include?(type)
          'inbox'
        end

        def reply_msg_template(original)
          %{
            <br/><br/>----------------------------------------<br/>
            #{I18n.t(:from, scope: [:messages, :show])} #{original.sent_by.to_msg[:resume]}<br/>
            #{I18n.t(:date, scope: [:messages, :show])} #{I18n.l(original.created_at, format: :clock)}<br/>
            #{I18n.t(:subject, scope: [:messages, :show])} #{original.subject}<br/>
            #{I18n.t(:to, scope: [:messages, :show])} #{original.users.map(&:to_msg).map{ |c| c[:resume] }.join(',')}<br/>
            #{original.content}
          }
        end

        def new_msg_template(allocation_tag_id, message)
          system_label = not(allocation_tag_id.nil?)

          %{
            <b>#{I18n.t(:mail_header, scope: :messages)} #{current_user.to_msg[:resume]}</b><br/>
            #{message.labels(current_user.id, system_label) if system_label}<br/>
            ________________________________________________________________________<br/><br/>
            #{message.content}
          }
        end

      end #helpers

      segment do

        before do
          verify_user_permission_and_set_obj(:index)
        end

        desc 'Listar todas as mensagens', {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          optional :group_id, type: Integer, desc: 'Group ID.'
          optional :box, type: String, desc: 'Box Type'
          optional :page, type: Integer, desc: 'Page', default: 1
        end #params

        get '/', rabl: 'messages/list' do
          @box = option_user_box(params[:box])
          @allocation_tag_id = params[:group_id].blank? ? [] : Group.find(params[:group_id]).allocation_tag.id
          page = (params[:page] || 1).to_i
          @messages = Message.by_box(current_user.id, @box, @allocation_tag_id, {page: page, ignore_at: true})

          limit = Rails.application.config.items_per_page
          @total = @messages.try(:first).total_messages rescue 0
          @pages_amount = (@total/limit).ceil.to_i + 1
        end

        desc 'Exibir anexos da mensagem', {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          requires :id, type: Integer
        end
        get "/:id/files" , rabl: 'messages/files' do
          @files = MessageFile.where(message_id: params[:id].to_i)
        end

        desc 'Remover mensagem do inbox para lixeira', {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          requires :id, type: Integer
        end
        delete ":id" do
          change_message_status(params[:id].to_i, 'trash', 'inbox')
          {ok: 'ok'}
        end

        desc 'Marcar mensagem como lida/não lida/restaurar', {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          requires :status, type: Symbol, values: [:read, :restore, :unread]
          requires :id, type: Integer
        end
        put "/:status/:id" do
          change_message_status(params[:id].to_i, params[:status].to_s, (params[:status] == :restore ? 'trashbox' : 'inbox'))
          {ok: 'ok'}
        end

        desc 'Recuperar lista de possíveis contatos', {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          requires :group_id, type: Integer
        end
        get '/:group_id/contacts', rabl: 'messages/contacts' do
          @contacts = User.all_at_allocation_tags(@allocation_tag_related, Allocation_Activated, true)
        end

        desc 'Responder/Encaminhar mensagem', {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          requires :id, type: Integer
          requires :group_id, type: Integer
          requires :message_type, type: Symbol, values: [:reply, :reply_all, :forward]
          optional :files, type: Array
          requires :message, type: Hash do
            requires :content, type: String
            optional :contacts, type: String # only message_type: forward
          end
        end
        post '/:message_type' do
          ActiveRecord::Base.transaction do
            original = Message.find(params[:id])
            allocation_tag_id = Group.find(params[:group_id]).allocation_tag.id

            message = Message.new
            message.api = true
            message.allocation_tag_id = allocation_tag_id
            message.content = reply_msg_template(original)
            message.content.insert(0, "#{params[:message][:content]} ")
            message.sender = current_user
            message.files = original.files unless original.files.empty?

            unless params[:files].blank?
              [params[:files]].flatten.each do |file|
                message.files.new({ attachment: ActionDispatch::Http::UploadedFile.new(file) })
              end
            end

            reply_to = []
            case params[:message_type]
              when :reply
                reply_to << original.sent_by.email
                message.contacts = [original.sent_by]
                message.subject = "#{I18n.t(:reply, scope: [:messages, :subject])} #{original.subject}"
              when :reply_all
                reply_to << original.sent_by.email
                reply_to.concat(original.recipients.map(&:email)).uniq!
                message.contacts = original.recipients.concat([original.sent_by])
                message.subject = "#{I18n.t(:reply, scope: [:messages, :subject])} #{original.subject}"
              when :forward
                raise 'contacts mandatory' if params[:message][:contacts].blank?

                users = User.joins('LEFT JOIN personal_configurations AS nmail ON users.id = nmail.user_id')
                            .where("(nmail.message IS NULL OR nmail.message=TRUE)")
                            .where(id: params[:message][:contacts].split(','))

                message.contacts = users
                reply_to = users.pluck(:email).flatten.compact.uniq
                message.subject = "#{I18n.t(:forward, scope: [:messages, :subject])} #{original.subject}"
            end

            if message.save!
              Job.send_mass_email(reply_to, message.subject, new_msg_template(allocation_tag_id, message), message.files.to_a, current_user.email)
              {id: message.id}
            else
              raise message.errors.full_messages
            end

          end

        end

      end #segment

    end #namespace message

    namespace :messages do

      helpers do
        # return a @message object
        def verify_user_permission_and_set_obj(permission) # permission = [:index, :create, ...]
          @group = params[:group_id].blank? ? nil : Group.find(params[:group_id])
          allocation_tag_related = @group.nil? ? nil : @group.allocation_tag.related
          @profile_id = current_user.profiles_with_access_on(permission, :messages, allocation_tag_related, true).first
          raise ActiveRecord::RecordNotFound if @profile_id.nil? || current_user.groups([@profile_id], Allocation_Activated).blank?
        end

        def option_user_box(type)
          return type if ['outbox', 'trashbox'].include?(type)
          'inbox'
        end

      end #helpers

      segment do

        before do
          # verify_user_permission_and_set_obj(:index)
        end

        desc 'Listar todas as mensagens', {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          optional :group_id, type: Integer, desc: 'Group ID.'
          optional :box, type: String, desc: 'Box Type'
          optional :page, type: Integer, desc: 'Page', default: 1
        end #params

        get '/', rabl: 'messages/list' do
          @box = option_user_box(params[:box])
          @allocation_tag_id = params[:group_id].blank? ? [] : Group.find(params[:group_id]).allocation_tag.id
          page = (params[:page] || 1).to_i
          @messages = Message.by_box(current_user.id, @box, @allocation_tag_id, {page: page, ignore_at: true})

          limit = Rails.application.config.items_per_page
          @total = @messages.try(:first).total_messages rescue 0
          @pages_amount = (@total/limit).ceil.to_i + 1
        end

      end #segment

    end

  end
end
