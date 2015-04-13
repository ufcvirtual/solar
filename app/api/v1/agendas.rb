module V1
  class Agendas < Base
    namespace :groups do

      before do
        @at = AllocationTag.find_by_group_id(params[:id])
        @ats = RelatedTaggable.related(group_id: params[:id])
      end

      ## api/v1/groups/1/agenda
      params { requires :id, type: Integer, desc: 'ID da turma' }
      get ":id/agenda" do
        authorize! :calendar, Agenda, {on: @ats, read: true}

        offer = Offer.joins(:groups).where(groups: { id: params[:id] }).first
        params = { semester: true, start: offer.start_date, end: offer.end_date }
        [Event.all_descendants(@ats, current_user, list = false, params)].flatten.map(&:api_json).uniq
      end # get

    end # namespace
  end
end
