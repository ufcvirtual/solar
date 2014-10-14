module V1
  class Events < Base

    segment do

      before { verify_ip_access! }

      namespace :integration do 

        namespace :event do

          desc "Edição de evento"
          params do
            requires :id, type: Integer, desc: "Event ID."
            requires :Data, :HoraInicio, :HoraFim
          end
          put "/:id" do
            begin
              event = ScheduleEvent.find(params[:id])

              ActiveRecord::Base.transaction do
                start_hour, end_hour = params[:HoraInicio].split(":"), params[:HoraFim].split(":")
                event.schedule.update_attributes! start_date: params[:Data], end_date: params[:Data]
                event.update_attributes! start_hour: [start_hour[0], start_hour[1]].join(":"), end_hour: [end_hour[0], end_hour[1]].join(":")
              end

              {ok: :ok}
            rescue => error
              error!({error: error}, 422)
            end
          end # put :id

        end # event

        namespace :events do
          
          desc "Criação de um ou mais eventos"
          params do
            requires :Turmas, type: Array
            requires :CodigoCurso, :CodigoDisciplina, :Periodo, type: String
            requires :DataInserida do
              requires :Data, :HoraInicio, :HoraFim, :Polo, :Tipo
            end
          end
          post "/" do
            group_events = []
            
            begin
              ActiveRecord::Base.transaction do
                offer = get_offer(params[:CodigoDisciplina], params[:CodigoCurso], nil, params[:Periodo])
                params[:Turmas].each do |code|
                  group_events << create_event(get_offer_group(offer, code), params[:DataInserida])
                end
              end

              group_events
            rescue => error
              error!({error: error}, 422)
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
            rescue => error
              error!({error: error}, 422)
            end
          end # delete :id

        end # events

      end # integration

    end # segment

  end
end