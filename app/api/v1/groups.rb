module V1
  class Groups < Base
    namespace :groups

    guard_all!

    # get ":id", rabl: "groups/show" do
    #   @group = Group.find(params[:id])
    # end

    get ":id/discussions", rabl: "discussions/list" do # Retorna os fóruns associados à uma turma
      @discussions = Discussion.all_by_allocation_tags(AllocationTag.find_related_ids(Group.find(params[:id]).allocation_tag.id))
    end

  end
end
