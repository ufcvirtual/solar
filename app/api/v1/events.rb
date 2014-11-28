module V1
  class Events < Base

    before { verify_ip_access! }

    namespace :event do
      desc "Edição de evento"
      params do
        requires :id, type: Integer
        requires :date, :start, :end
      end
      put "/:id" do
        begin
          event = ScheduleEvent.find(params[:id])

          ActiveRecord::Base.transaction do
            start_hour, end_hour = params[:start].split(":"), params[:end].split(":")
            event.schedule.update_attributes! start_date: params[:date], end_date: params[:date]
            event.update_attributes! start_hour: [start_hour[0], start_hour[1]].join(":"), end_hour: [end_hour[0], end_hour[1]].join(":")
          end

          {ok: :ok}
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
            params[:groups].each do |code|
              group_events << create_event(get_offer_group(offer, code), params[:event])
            end
          end

          group_events
        end

      end # /

      desc "Remoção de um ou mais eventos"
      params { requires :ids, type: String, desc: "Events IDs." }
      delete "/:ids" do
        begin
          ScheduleEvent.transaction do
            ScheduleEvent.where(id: params[:ids].split(",")).destroy_all
          end

          {ok: :ok}
        end
      end # delete :id

    end # events

  end
end