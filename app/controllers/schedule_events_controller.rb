class ScheduleEventsController < ApplicationController

  include SysLog::Actions

  before_action :prepare_for_group_selection, only: :index
  before_action :get_groups_by_allocation_tags, only: [:new, :create]

  before_action only: [:edit, :update, :show] do |controller|
    @allocation_tags_ids = params[:allocation_tags_ids]
    get_groups_by_tool(@schedule_event = ScheduleEvent.find(params[:id]))
  end

  layout false, except: :index

  def index
    authorize! :index, ScheduleEvent, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    @is_student = current_user.is_student?([@allocation_tag_id])
    @events = Score.list_tool(current_user.id, @allocation_tag_id, 'schedule_events', false, false, true)
    @can_print = can? :print_presential_test, ScheduleEvent, on: [@allocation_tag_id]
  end

  def list
    authorize! :list, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @events = ScheduleEvent.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(' ').flatten}).uniq
  end

  def show
    authorize! :show, ScheduleEvent, on: @allocation_tags_ids
  end

  def new
    authorize! :new, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @schedule_event = ScheduleEvent.new
    @schedule_event.build_schedule(start_date: Date.today, end_date: Date.today)
  end

  def create
    authorize! :new, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @schedule_event = ScheduleEvent.new schedule_event_params
    @schedule_event.allocation_tag_ids_associations = @allocation_tags_ids.split(" ").flatten

    if @schedule_event.save
      render_schedule_event_success_json('created')
    else
      render :new
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def edit
    authorize! :edit, ScheduleEvent, on: @allocation_tags_ids
  end

  def update
    authorize! :edit, ScheduleEvent, on: @schedule_event.academic_allocations.pluck(:allocation_tag_id)

    if @schedule_event.can_change? && @schedule_event.update_attributes(schedule_event_params)
      render_schedule_event_success_json('updated')
    elsif Presential_Test == @schedule_event.type_event.to_i && !@schedule_event.can_change? && @schedule_event.update_attributes(content_exam: params[:schedule_event][:content_exam])
      render_schedule_event_success_json('updated_content')
    else
      render :edit
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def destroy
    @schedule_event = ScheduleEvent.find(params[:id])
    authorize! :destroy, ScheduleEvent, on: @schedule_event.academic_allocations.pluck(:allocation_tag_id)

    evaluative = @schedule_event.verify_evaluatives
    if @schedule_event.can_remove_groups? && @schedule_event.can_change?
      @schedule_event.destroy
      message = evaluative ? ['warning', t('evaluative_tools.warnings.evaluative')] : ['notice', t(:deleted, scope: [:schedule_events, :success])]
      render json: { success: true, type_message: message.first,  message: message.last }
    else
      render json: {success: false, alert: t('schedule_events.error.evaluated')}, status: :unprocessable_entity
    end
  rescue => error
    render_json_error(error, 'schedule_events.error')
  end

  def summarized
    @allocation_tag_id = active_tab[:url][:allocation_tag_id]

    raise CanCan::AccessDenied if params[:user_id].to_i != current_user.id && !AllocationTag.find(@allocation_tag_id).is_observer_or_responsible?(current_user.id)

    @schedule_event = ScheduleEvent.find(params[:id])
    @ac = (params[:ac_id].blank? ? @schedule_event.academic_allocations.where(allocation_tag_id: @allocation_tag_id).first : AcademicAllocation.find(params[:ac_id]))

    @user = User.find((params[:user_id].blank? ? current_user.id : params[:user_id]))
    @student_id = params[:user_id]
    @score_type = params[:score_type]
    @situation = params[:situation]

    @can_evaluate = can? :evaluate, ScheduleEvent, { on: @allocation_tag_id }
    @back_to_participants = params[:back_to_participants]

    raise 'not_student' unless @user.has_profile_type_at(@allocation_tag_id)
    @acu = AcademicAllocationUser.find_or_create_one(@ac.id, @allocation_tag_id, @user.id, params[:group_id], false, nil)

    render partial: 'summarized'
  rescue CanCan::AccessDenied
    render text: t(:no_permission)
  rescue => error
    error_message = (I18n.translate!("schedule_events.error.#{error}", raise: true) rescue t("schedule_events.error.general_message"))
    render text: error_message
  end

  def participants
    raise CanCan::AccessDenied unless AllocationTag.find(@allocation_tag_id = active_tab[:url][:allocation_tag_id]).is_observer_or_responsible?(current_user.id)
    @event = ScheduleEvent.find(params[:id])
    @participants = @event.participants(@allocation_tag_id)

    @can_evaluate = (can? :evaluate, ScheduleEvent, { on: @allocation_tag_id })
    @can_print = (can? :print_presential_test, ScheduleEvent, on: [@allocation_tag_id]) && Presential_Test == @event.type_event.to_i
    @can_send_file = (can? :create, ScheduleEventFile, on: @allocation_tag_id)

    render partial: 'participants'
  end

  def presential_test_participants
    raise CanCan::AccessDenied unless AllocationTag.find(@allocation_tag_id = (params[:allocation_tags_ids].blank? ? [active_tab[:url][:allocation_tag_id]] : params[:allocation_tags_ids].split(' '))).first.is_observer_or_responsible?(current_user.id)

    @event = ScheduleEvent.find(params[:id])
    @participants = AllocationTag.get_participants(@allocation_tag_id, { students: true })

    render partial: 'presential_test_participants'
  end

  def print_presential_test
    begin
      authorize! :print_presential_test, ScheduleEvent, on: @allocation_tags_ids = (params[:allocation_tags_ids].blank? ? [active_tab[:url][:allocation_tag_id]] : params[:allocation_tags_ids].split(' ')).flatten
    rescue
      authorize! :create, ScheduleEvent, on: @allocation_tags_ids
    end

    allocation_tag = AllocationTag.find(@allocation_tags_ids.first)
    ats = allocation_tag.related

    @course = allocation_tag.get_course
    @event = ScheduleEvent.find(params[:id])

    if @event.content_exam.blank?
      render text: t("schedule_events.error.no_content")
    else

      html = HTMLEntities.new.decode render_to_string("print_presential_test.html.haml", formats: [:html], layout: false)

      curriculum_unit = allocation_tag.get_curriculum_unit

      unless @allocation_tags_ids.size > 1
        coordinator = User.joins(:allocations).where("allocations.allocation_tag_id IN (?) AND allocations.status = ? AND allocations.profile_id = 8", ats, Allocation_Activated).first

        profs = User.joins(:allocations).where("allocations.allocation_tag_id IN (?) AND allocations.status = ? AND allocations.profile_id IN (?)", ats, Allocation_Activated, [2, 17]).distinct

        tutors = User.joins(:allocations).where("allocations.allocation_tag_id IN (?) AND allocations.status = ? AND allocations.profile_id IN (?)", ats, Allocation_Activated, [3, 4, 18]).distinct
      end

      student = User.find(params[:student_id]) unless params[:student_id].blank?

      normalize_exam_header(html, student, profs, tutors, @event, curriculum_unit, coordinator)

      pictures_with_abs_path html

      pdf = WickedPdf.new.pdf_from_string(html)
      send_data(pdf, filename: "#{@event.title}.pdf", type: "application/pdf",  disposition: 'inline')
    end
  end

  private

    def schedule_event_params
      params.require(:schedule_event).permit(:title, :description, :type_event, :start_hour, :end_hour, :place, :integrated, :content_exam, schedule_attributes: [:id, :start_date, :end_date])
    end

    def render_schedule_event_success_json(method)
      render json: {success: true, notice: t(method, scope: 'schedule_events.success')}
    end

    def fill_field_info(html, pattern, name)
      html.sub!(pattern, name)
    end

    # def normalize_exam_header(html, student, profs, tutors, event, curriculum_unit, coordinator)
    #   fill_field_info html, /disciplina:(\s*\n*\t*(&nbsp;)*)/i, "Disciplina: #{curriculum_unit.code} - #{curriculum_unit.name}<br>" unless curriculum_unit.nil?
    #   fill_field_info html, /(coordenador\(a\)(\s*\n*\t*(&nbsp;)*)da(\s*\n*\t*(&nbsp;)*)disciplina:|coordenador(\s*\n*\t*(&nbsp;)*)da(\s*\n*\t*(&nbsp;)*)disciplina:|coordenador:(\s*\n*\t*(&nbsp;)*))/i, "Coordenador(a) da disciplina: #{coordinator.name}<br>" unless coordinator.nil?
    #   fill_field_info html, /(nome(\s*\n*\t*(&nbsp;)*)do\(a\)(\s*\n*\t*(&nbsp;)*)aluno\(a\):(\s*\n*\t*(&nbsp;)*)|nome(\s*\n*\t*(&nbsp;)*)do(\s*\n*\t*(&nbsp;)*)aluno:|aluno:)/i, "Nome do(a) aluno(a): #{student.name}<br>" unless student.nil?
    #   unless event.nil?
    #     # fill_field_info html, /polo:(\s*\n*\t*(&nbsp;)*)|pólo:(\s*\n*\t*(&nbsp;)*)/i, "Polo: #{event.place}<br>"
    #     fill_field_info html, /prova:(\s*\n*\t*(&nbsp;)*)/i, "Prova: #{event.title}<br>"
    #     fill_field_info html, /data:(\s*\n*\t*(&nbsp;)*)/i, "Data: #{event.get_date}<br>"
    #   end
    #   profs.each { |prof| fill_field_info html, /(professor\(a\)(\s*\n*\t*(&nbsp;)*)titular:(\s*\n*\t*(&nbsp;)*)|professor(\s*\n*\t*(&nbsp;)*)titular:(\s*\n*\t*(&nbsp;)*)|professor:(\s*\n*\t*(&nbsp;)*))/i, "Professor(a) da disciplina: #{prof.name}<br>"  } unless profs.nil? || profs.empty?
    #   tutors.each { |tutor| fill_field_info html, /(tutor\(a\)(\s*\n*\t*(&nbsp;)*)da(\s*\n*\t*(&nbsp;)*)disciplina:(\s*\n*\t*(&nbsp;)*)|tutor(\s*\n*\t*(&nbsp;)*)da(\s*\n*\t*(&nbsp;)*)disciplina:(\s*\n*\t*(&nbsp;)*)|tutor:(\s*\n*\t*(&nbsp;)*))/i, "Tutor(a) da disciplina: #{tutor.name}<br>"  } unless tutors.nil? || tutors.empty?
    # end

    def normalize_exam_header(html, student, profs, tutors, event, curriculum_unit, coord)
      fill_field_info html, /disciplina:(\s*\n*\t*(&nbsp;)*)/i, "Disciplina: <b>#{curriculum_unit.code} - #{curriculum_unit.name}</b><br>" unless curriculum_unit.nil?
      fill_field_info html, /(nome(\s*\n*\t*(&nbsp;)*)do\(a\)(\s*\n*\t*(&nbsp;)*)aluno\(a\):(\s*\n*\t*(&nbsp;)*)|nome(\s*\n*\t*(&nbsp;)*)do(\s*\n*\t*(&nbsp;)*)aluno:|aluno:)/i, "Nome do(a) aluno(a): #{student.name}<br>" unless student.nil?
      unless event.blank?
        fill_field_info html, /prova:(\s*\n*\t*(&nbsp;)*)/i, "Prova: <b>#{event.title}</b>"
        fill_field_info html, /data:(\s*\n*\t*(&nbsp;)*)/i, "Data: #{event.get_date}"
      end
      profs.each { |prof| fill_field_info html, /(professor\(a\)(\s*\n*\t*(&nbsp;)*)titular:(\s*\n*\t*(&nbsp;)*)|professor(\s*\n*\t*(&nbsp;)*)titular:(\s*\n*\t*(&nbsp;)*)|professor:(\s*\n*\t*(&nbsp;)*)|coordenador\(a\)(\s*\n*\t*(&nbsp;)*)de(\s*\n*\t*(&nbsp;)*)disciplina:(\s*\n*\t*(&nbsp;)*)|coordenador\(a\)(\s*\n*\t*(&nbsp;)*)da(\s*\n*\t*(&nbsp;)*)disciplina:(\s*\n*\t*(&nbsp;)*))/i, "Professor(a) da disciplina: #{prof.name}<br>"  } unless profs.blank?
      tutors.each { |tutor| fill_field_info html, /(tutor\(a\)(\s*\n*\t*(&nbsp;)*)à(\s*\n*\t*(&nbsp;)*)distância:(\s*\n*\t*(&nbsp;)*)|tutor(\s*\n*\t*(&nbsp;)*)à(\s*\n*\t*(&nbsp;)*)distância:(\s*\n*\t*(&nbsp;)*)|tutor:(\s*\n*\t*(&nbsp;)*))/i, "Tutor(a) à distância: #{tutor.name}<br>"  } unless tutors.blank?
    end




    def pictures_with_abs_path(html)
      html.gsub!(/(href|src)=(['"])\/([^\"']*|[^"']*)['"]/i, '\1=\2' + "#{Rails.root}/" + '\3\2')
    end


end
