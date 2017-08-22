module V1
  class Messages < Base

    guard_all!

    namespace :messages do

      helpers do
        # return a @message object
        def verify_user_permission_and_set_obj(permission) # permission = [:index, :create, ...]
                    
          @message = Message.find(params[:id])
          @group = Group.find(params[:group_id])
          @profile_id = current_user.profiles_with_access_on(permission, :messages, @group.allocation_tag.related, true).first

          raise ActiveRecord::RecordNotFound if @profile_id.nil? || !(current_user.groups([@profile_id], Allocation_Activated).include?(@group))
        end
      end

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
    end #namespace
  end #class Messages
end #module v1
