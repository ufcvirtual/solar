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
    end #namespace message

    namespace :messages do

      helpers do
        # return a @message object
        def verify_user_permission_and_set_obj(permission) # permission = [:index, :create, ...]
          @group = Group.find(params[:group_id])
          @profile_id = current_user.profiles_with_access_on(permission, :messages, @group.allocation_tag.related, true).first
          raise ActiveRecord::RecordNotFound if @profile_id.nil? || !(current_user.groups([@profile_id], Allocation_Activated).include?(@group))
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
        
        get "/:all", rabl: 'messages/list' do
        end
      end #segment
    end #namespace all
  end #class Messages
end #module v1
