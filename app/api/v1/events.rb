module V1
  class Events < Base

    # before { verify_ip_access_and_guard! }
    guard_all!

    namespace :event do
      desc "Edição de ac de evento"
      params do
        requires :id, type: Integer
        requires :date, :start, :end
      end
      put "/:id" do
        begin
          ac = AcademicAllocation.where(id: params[:id], academic_tool_type: 'ScheduleEvent').first
          raise ActiveRecord::RecordNotFound if ac.blank?
          event = ScheduleEvent.find(ac.academic_tool_id)

          ActiveRecord::Base.transaction do
            start_hour, end_hour = params[:start].split(":"), params[:end].split(":")
            create_event({event: {date: params[:date], start: params[:start], end: params[:end], title: event.title, type_event: event.type_event}}, ac.allocation_tag.group.offer.allocation_tag.related, nil, ac, (event.academic_allocations.count == 1 ? event : nil))

            {id: ac.id}
          end
        end
      end

    end # event

    namespace :events do

      # helpers do
        
      #   def schedule_event_file_params
      #     ActionController::Parameters.new(params).require(:schedule_event_file).permit(:user_id, :academic_allocation_user_id, :attachment, :file_correction)
      #   end
      # end

      desc "Criação de um ou mais eventos"
      params do
        requires :groups, type: Array
        requires :course_code, :curriculum_unit_code, :semester, type: String
        requires :event, type: Hash do
          requires :date
          requires :start, :end, type: String
          requires :type, type: Integer
        end
      end
      post "/" do
        group_events = []

        begin
          ActiveRecord::Base.transaction do
            offer = get_offer(params[:curriculum_unit_code], params[:course_code], params[:semester])
            group_events = create_event(params, offer.allocation_tag.related, offer)
          end
          group_events
        end

      end # /

      desc "Remoção de um ou mais acs de eventos"
      params do
        requires :ids, type: String, desc: "Events IDs."
      end
      delete "/:ids" do
        begin
          AcademicAllocation.transaction do
            acs = AcademicAllocation.where(id: params[:ids].split(','), academic_tool_type: 'ScheduleEvent')
            raise ActiveRecord::RecordNotFound if acs.empty?
            event = ScheduleEvent.find(acs.first.academic_tool_id)

            if acs.count == event.academic_allocations.count
              event.api = true
              raise event.errors.full_messages unless event.destroy
            else
              acs.destroy_all
            end
          end

          {ok: :ok}
        end
      end # delete :id

      segment do
      
        desc "Listar Eventos"
        params do
          requires :allocation_tag_id, type: Integer, desc: "AllocationTagId"
        end
        get "/", rabl: 'events/list' do
           @events = ScheduleEvent.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: params[:allocation_tag_id].to_i})
        end
      
      end

      segment do
      
        desc "Listar Alunos"
        params do
          requires :allocation_tag_id, type: Integer, desc: "AllocationTagId"
        end
        get ":id/participants", rabl: 'events/users' do
          schedule_event = ScheduleEvent.find(params[:id].to_i)
          @users = schedule_event.participants(params[:allocation_tag_id])
        end
      
      end

    end # events

  end
end