module V1
  class Discussions < Base
    guard_all!

    namespace :groups do
      desc "Lista de fóruns da turma"
      params { requires :id, type: Integer }#, values: -> { Group.all.map(&:id) } }
      get ":id/discussions", rabl: "discussions/list" do
        @group = Group.find(params[:id])
        raise ActiveRecord::RecordNotFound if @group.nil?

        @discussions = Discussion.all_by_allocation_tags(@group.allocation_tag.id)
        ats = @group.allocation_tag.related
        @researcher = current_user.is_researcher?(ats)
        @can_post   = profiles_with_access_on('create', 'posts', ats).any?
      end
    end

  end
end
