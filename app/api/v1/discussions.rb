module V1
  class Discussions < Base
    guard_all!

    namespace :groups do
      desc "Lista de fóruns da turma"
      params { requires :id, type: Integer }#, values: -> { Group.all.map(&:id) } }
      get ":id/discussions", rabl: "discussions/list" do
        @group = Group.find(params[:id])
        raise ActiveRecord::RecordNotFound if @group.nil?
        #ats = @group.allocation_tag.related
        at_ids = AllocationTag.find(@group.allocation_tag.id).related
        @discussions = Discussion.all_by_allocation_tags(at_ids)
        @researcher = current_user.is_researcher?(at_ids)
        @can_post   = current_user.profiles_with_access_on('create', 'posts', at_ids).any?
      end
    end

  end
end
