module V1
  class Events < Base

    before { verify_ip_access_and_guard! }

    namespace :event do
      desc "Edição de evento"
      params do
        requires :groups, type: Array
        requires :course_code, :curriculum_unit_code, :semester, type: String
        requires :id, type: Integer
        requires :date, :start, :end
      end
      put "/:id" do
        begin
          event = ScheduleEvent.find(params[:id])

          ActiveRecord::Base.transaction do
            # if editing all groups of event (when size is not one)
            if event.academic_allocations.size == params[:groups].size && params[:groups].size > 1
              start_hour, end_hour = params[:start].split(":"), params[:end].split(":")
              event.schedule.update_attributes! start_date: params[:date], end_date: params[:date]
              event.api = true
              # just update event
              event.update_attributes! start_hour: [start_hour[0], start_hour[1]].join(":"), end_hour: [end_hour[0], end_hour[1]].join(":")

              {id: event.id}
            else
              # if editing less than all groups
              offer = get_offer(params[:curriculum_unit_code], params[:course_code], params[:semester])
              all_groups = event.academic_allocations.size == params[:groups].size
              # create a new event or find one that already exists
              group_events = create_event({event: {date: params[:date], start: params[:start], end: params[:end], title: event.title, type_event: event.type_event}, groups: params[:groups]}, offer.allocation_tag.related, offer, event)

              # if event found is not the same of the request
              if group_events.first[:id] != event.id && all_groups
                # remove event if last group or remove group ac 
                event.api = true
                event.destroy
              end

              {id: group_events.first[:id]}
            end
          end
        end
      end

    end # event

    namespace :events do
      
      desc "Criação de um ou mais eventos"
      params do
        requires :groups, type: Array
        requires :course_code, :curriculum_unit_code, :semester, type: String
        requires :event, type: Hash do
          requires :date
          requires :start, :end, :place, type: String
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

      desc "Remoção de um ou mais eventos"
      params do
        requires :ids, type: String, desc: "Events IDs."
        requires :groups, type: Array
        requires :course_code, :curriculum_unit_code, :semester, type: String
      end
      delete "/:ids" do
        begin
          ScheduleEvent.transaction do
            offer = get_offer(params[:curriculum_unit_code], params[:course_code], params[:semester])
            events = ScheduleEvent.where(id: params[:ids].split(","))

            params[:groups].each do |code|
              group = get_offer_group(offer, code)
              group_at = group.allocation_tag.id

              events.each do |event|
                if event.academic_allocations.size > 1 || event.academic_allocations.first.allocation_tag_id != group_at
                  event.academic_allocations.where(allocation_tag_id: group_at).destroy_all
                else
                  event.api = true
                  raise event.errors.full_messages unless event.destroy
                end
              end
            end
          end

          {ok: :ok}
        end
      end # delete :id

    end # events

  end
end