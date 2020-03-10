module V1
  class Events < Base

    namespace :events do

      helpers do

        def verify_user_permission_on_events_and_set_obj(permission, controller = :schedule_events) # permission = [:index, :create, ...]
          @group = Group.find(params[:group_id])
          @at = @group.allocation_tag
          @profile_id = current_user.profiles_with_access_on(permission, controller, @group.allocation_tag.related, true).first
          raise CanCan::AccessDenied if @profile_id.nil? || !(current_user.groups([@profile_id], Allocation_Activated).include?(@group))
        end

        def is_responsible(permission,  controler = :schedule_events)
          verify_user_permission_on_events_and_set_obj(permission, controler)

          raise  CanCan::AccessDenied unless current_user.id == params[:student_id].to_i || AllocationTag.find(@at.id).is_observer_or_responsible?(current_user.id)
        end

      end

      segment do

        before { verify_ip_access_and_guard! }

        desc "Criação de um ou mais Eventos padrão"
        params do
          requires :groups, type: Array, desc: 'Nome da(s) turma(s) onde o evento será criado'
          requires :course_code, :curriculum_unit_code, :semester, type: String
          requires :event, type: Hash do
            requires :date
            requires :start, :end, type: String
            requires :type, type: Integer
          end
        end
        post "/" do
          group_events = []

          startd = DateTime.parse("#{params[:event][:date]} #{params[:event][:start]}")
          endd = DateTime.parse("#{params[:event][:date]} #{params[:event][:end]}")
          raise 'end_smaller_than_start' if endd <= startd

          begin
            ActiveRecord::Base.transaction do
              offer = get_offer(params[:curriculum_unit_code], params[:course_code], params[:semester])
              group_events = create_event(params, offer.allocation_tag.related, offer)
            end
            group_events
          end

        end

        desc "Edição de Evento"
        params do
          requires :id, type: Integer, desc: 'ID do AcademicAllocation do Evento'
          requires :date, :start, :end
        end
        put "/:id" do
          begin
            startd = DateTime.parse("#{params[:date]} #{params[:start]}")
            endd = DateTime.parse("#{params[:date]} #{params[:end]}")
            raise 'end_smaller_than_start' if endd <= startd

            ac = AcademicAllocation.find(params[:id])
            raise ActiveRecord::RecordNotFound if ac.blank?
            event =  ac.academic_tool_type == 'ScheduleEvent' ? ScheduleEvent.find(ac.academic_tool_id) : Webconference.find(ac.academic_tool_id)

            ActiveRecord::Base.transaction do
              create_event({event: {date: params[:date], start: params[:start], end: params[:end], title: event.title, type: (ac.academic_tool_type == 'ScheduleEvent' ? event.type_event : 6)}}, ac.allocation_tag.group.offer.allocation_tag.related, nil, ac, (event.academic_allocations.count == 1 ? event : nil))

              {id: ac.id}
            end
          end

        end

        desc "Remoção de um ou Eventos"
        params do
          requires :ids, type: String, desc: "ID(s) do(s) AcademicAllocation(s) do(s) Evento(s)"
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
        end

      end

      segment do

        guard_all!

        before do
          verify_user_permission_on_events_and_set_obj(:index)
        end # befor

        desc "Listar Eventos"
        params do
          requires :group_id, type: Integer, desc: "Group Id"
        end
        get "/", rabl: 'events/list' do
          @is_student  = !@at.is_observer_or_responsible?(current_user.id)
          @events = Score.list_tool(current_user.id, @at.id, 'schedule_events', false, false, true)
        end
      end

      segment do
        guard_all!

         before do
          is_responsible(:index, :schedule_events)
        end

        desc "Listar Sumário dos Alunos"
        params do
          requires :id, type: Integer, desc: "ID do Evento"
          requires :group_id, type: String, desc: "Group Id"
        end
        get ":id/participants", rabl: 'events/summary' do
          @event = ScheduleEvent.find(params[:id].to_i)
          @users = AllocationTag.get_participants(@at.id, { students: true })
        end

        # desc "Enviar arquivo para aluno"
        # params do
        #   requires :academic_allocation_id, type: Integer, desc: "ID do AcademicAllocation do Evento"
        #   requires :student_id, type: Integer, desc: 'ID do Aluno'
        #   requires :file, type: File
        #   requires :group_id, type: String, desc: "Group Id"
        # end
        # post ":academic_allocation_id/students/:student_id/files" do
        #   academic_allocation_user = AcademicAllocationUser.where(user_id: params[:student_id], academic_allocation_id: params[:academic_allocation_id]).first

        #   sef = ScheduleEventFile.new({user_id: current_user.id, academic_allocation_user_id: academic_allocation_user.id, attachment: ActionDispatch::Http::UploadedFile.new(params[:file])})
        #   sef.api = true
        #   sef.save!

        #   {ok: :ok}
        # end

      end

    end

  end
end