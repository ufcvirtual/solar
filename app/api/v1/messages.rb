module V1
  class Messages < Base

    guard_all!

    namespace :message do

      helpers do
        # return a @message object
        def verify_user_permission_and_set_obj(permission) # permission = [:index, :create, ...]
          @message = Message.find(params[:id])
          @group = Group.find(params[:group_id])
          @profile_id = current_user.profiles_with_access_on(permission, :messages, @group.allocation_tag.related, true).first

          raise ActiveRecord::RecordNotFound if @profile_id.nil? || !(current_user.groups([@profile_id], Allocation_Activated).include?(@group))
        end

        def message_params
          ActionController::Parameters.new(params).require(:message).permit(:content, :id, :subject)
        end

      end #helpers

      segment do
        before do
          verify_user_permission_and_set_obj(:index)
        end # before

        # messages/10
        desc 'Exibir mensagem'
        params do
          requires :group_id, type: Integer, desc: 'Group ID.'
        end

        get "/:id" , rabl: 'messages/show' do   
        end
      end #segment

      segment do

        # CREATE 
        desc 'Compor Mensagem'
        params do
          requires :message, type: Hash do
            requires :content, type: String
            requires :subject, type: String
            optional :parent_id, type: Integer
            optional :draft, type: Boolean, default: false
          end
        end

        post '/' do

        @group = Group.find(params[:group_id])
        
        raise CanCan::AccessDenied if current_user.profiles_with_access_on(:index, :messages, @group.allocation_tag.related, true).blank? # unauthorized

          @message = Message.new(message_params)
          @message.sender = current_user

          if @message.save
            { id: @message.id }
          else
            raise @message.errors.full_messages
          end
        end #end post
      end #segment
    end #namespace message

    namespace :messages do

      helpers do
        # return a @message object
        def verify_user_permission_and_set_obj(permission) # permission = [:index, :create, ...]
          @group = Group.find(params[:group_id])
          @profile_id = current_user.profiles_with_access_on(permission, :messages, @group.allocation_tag.related, true).first
          raise ActiveRecord::RecordNotFound if @profile_id.nil? || !(current_user.groups([@profile_id], Allocation_Activated).include?(@group))
        end

        def option_user_box(type)
          return type if ['outbox', 'trashbox'].include?(type)
          'inbox'
        end
      end #helpers

      segment do
        before do
          verify_user_permission_and_set_obj(:index)
        end #before

        #listar todas as mensagens
        desc 'Listar todas as mensagens'
        params do
          requires :group_id, type: Integer, desc: 'Group ID.'
          # requires :user_id, type: Integer, desc: 'User ID.'
          optional :limit, type: Integer, desc: 'Messages limit.', default: Rails.application.config.items_per_page.to_i
          optional :page, type: Integer, desc: 'Page', default: 1
        end #params
        
        get :all, rabl: 'messages/list' do
          @box = option_user_box(params[:box])
          @allocation_tag_id = Group.find(params[:group_id]).allocation_tag.id
          @messages = Message.by_box(current_user.id, @box, @allocation_tag_id)
        end
      end #segment
    end #namespace all
  end #class Messages
end #module v1
