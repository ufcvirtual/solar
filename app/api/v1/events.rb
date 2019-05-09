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
          ac = AcademicAllocation.find(params[:id])
          raise ActiveRecord::RecordNotFound if ac.blank?
          event =  ac.academic_tool_type == 'ScheduleEvent' ? ScheduleEvent.find(ac.academic_tool_id) : Webconference.find(ac.academic_tool_id)

          ActiveRecord::Base.transaction do
            # start_hour, end_hour = params[:start].split(":"), params[:end].split(":")
            create_event({event: {date: params[:date], start: params[:start], end: params[:end], title: event.title, type_event: (ac.academic_tool_type == 'ScheduleEvent' ? event.type_event : 6)}}, ac.allocation_tag.group.offer.allocation_tag.related, nil, ac, (event.academic_allocations.count == 1 ? event : nil))

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
            acs = AcademicAllocation.where(id: params[:ids].split(','))
            raise ActiveRecord::RecordNotFound if acs.empty?
            event =  acs.first.academic_tool_type == 'ScheduleEvent' ? ScheduleEvent.find(acs.first.academic_tool_id) : Webconference.find(acs.first.academic_tool_id)

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

      segment do

        desc "Listar Responsáveis"
        params do
          requires :allocation_tag_id, type: Integer, desc: "AllocationTagId"
        end
        get ":id/responsibles", rabl: 'events/users' do
          @users =  Allocation.responsibles(params[:allocation_tag_id])
        end

      end

      segment do

        desc "Enviar arquivo para aluno"
        post "/send_file" do
          academic_allocation = AcademicAllocation.where(allocation_tag_id: params[:allocation_tag_id].to_i).where(academic_tool_id: params[:id].to_i)
          academic_allocation_user = AcademicAllocationUser.where(academic_allocation_id: academic_allocation[0].id).where(user_id: params[:student_id].to_i)

          sef = ScheduleEventFile.new({user_id: current_user.id, academic_allocation_user_id: academic_allocation_user[0].id, attachment: ActionDispatch::Http::UploadedFile.new(params[:file])})
          sef.api = true
          sef.save!

          {ok: :ok}
        end

      end

      segment do

        desc "Ver nota do aluno"
        params do
          requires :event_id, type: Integer, desc: "ID do Evento"
          requires :student_id, type: Integer, desc: "ID do Aluno"
          requires :allocation_tag_id, type: Integer, desc: "AllocationTagId da Turma"
        end
        get ":event_id/grade/:student_id" do
          schedule_event = ScheduleEvent.find(params[:event_id].to_i)
          users = schedule_event.participants(params[:allocation_tag_id].to_i)
          student = users.select{|u| u.id == params[:student_id].to_i}[0]

          {student_id: student.id, student_grade: student.grade}
        end

      end

      segment do

        desc "Listar Arquivos enviado para o Aluno"
        params do
          requires :id, type: Integer, desc: "ID do Evento"
          requires :student_id, type: Integer, desc: "ID do Aluno"
          requires :allocation_tag_id, type: Integer, desc: "AllocationTagId da Turma"
        end
        get ":id/sent_files/:student_id", rabl: 'events/files' do
          academic_allocation = AcademicAllocation.where(allocation_tag_id: params[:allocation_tag_id].to_i).where(academic_tool_id: params[:id].to_i)
          academic_allocation_user = AcademicAllocationUser.where(academic_allocation_id: academic_allocation[0].id).where(user_id: params[:student_id].to_i)

          @schedule_event_files = ScheduleEventFile.where(academic_allocation_user_id: academic_allocation_user[0].id)
        end

      end

      segment do

        desc "Listar comentários do responsável para o Aluno"
        params do
          requires :event_id, type: Integer, desc: "ID do Evento"
          requires :student_id, type: Integer, desc: "ID do Aluno"
          requires :allocation_tag_id, type: Integer, desc: "AllocationTagId da Turma"
        end
        get ":event_id/comments/:student_id", rabl: 'events/comments' do
          schedule_event = ScheduleEvent.find(params[:event_id])
          ac = schedule_event.academic_allocations.where(allocation_tag_id: params[:allocation_tag_id].to_i).first
          acu = AcademicAllocationUser.where(academic_allocation_id: ac.id).where(user_id: params[:student_id]).first

          @comments = acu.comments
        end

      end

    end # events

  end
end
