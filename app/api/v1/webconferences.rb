module V1
  class Webconferences < Base
    namespace :webconferences do

      before do
        @at = AllocationTag.find_by_group_id(params[:id])
      end

      ## api/v1/webconferences/1/
      params { requires :id, type: Integer, desc: 'ID da turma' }
      get ":id/" do
        authorize! :index, Webconference, {on: @at.id, read: true}

        user = current_user
        is_student = user.is_student?([@at.id])

        @webconferences = Webconference.all_by_allocation_tags(AllocationTag.find(@at.id).related(upper: true), {asc: true}, user.id)
        @webconferences.map{ |web|
          url = "/api/v1/webconferences/#{params[:id]}/access_url?webconfecere_id=#{web.id}"
          recordings = web.recordings([], (@at.id.class == Array ? nil : @at.id))
          ac_id =  AcademicAllocation.where(academic_tool_type: 'Webconference', academic_tool_id: (web.id), allocation_tag_id: @at.id).first.try(:id)
          acu = AcademicAllocationUser.find_or_create_one(ac_id, @at, user.id, nil, false)
          comments = acu.comments

          {
            id: web.id, 
            name: web.title, 
            start: web.initial_time, 
            duration: web.duration, 
            situation: web.situation, 
            grade: web.grade, 
            hours: web.working_hours, 
            evaluative: web.evaluative, 
            frequency: web.frequency, 
            access_url: url, 
            recordings: recordings.map do |record|
              {
                recordding_url: Bbb.get_recording_url(record)
              }
            end,
            comments: comments.map do |c|
              {
                comment: c.comment
              }
            end
          }
        }  
      end # get
      desc "Retorna link para acesso a Webconferencia"
        params do
          requires :id, type: Integer
          requires :webconfecere_id, type: Integer
        end
      get ":id/access_url", rabl: 'webconferences/access_url' do
        authorize! :interact, Webconference, {on: @at.id}
        webconference = Webconference.find(params[:webconfecere_id])
        @url = webconference.link_to_join(current_user, @at.id, true)

      end # get

    end # namespace
  end
end