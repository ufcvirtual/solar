module V1
  class Scores < Base

    namespace :groups do

      before do
        @at = AllocationTag.find_by_group_id(params[:id])
        @ats = RelatedTaggable.related(group_id: params[:id])
      end

      ## api/v1/groups/1/scores/info
      params { requires :id, type: Integer, desc: "ID da turma" }
      get ":id/scores/info" do
        authorize! :info, Score, on: @ats, read: true

        @info = Score.informations(current_user.id, @at, related: @ats)
      end # get

    end # namespace

  end
end
