class ScheduleEventsController < ApplicationController

  include SysLog::Actions

  before_action :prepare_for_group_selection, only: :index
  before_filter :get_groups_by_allocation_tags, only: [:new, :create]

  before_filter only: [:edit, :update, :show] do |controller|
    @allocation_tags_ids = params[:allocation_tags_ids]
    get_groups_by_tool(@schedule_event = ScheduleEvent.find(params[:id]))
  end

  layout false, except: :index

  def index
    authorize! :index, ScheduleEvent, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    allocation_tag = AllocationTag.find(@allocation_tag_id)
    @is_student = current_user.is_student?([allocation_tag.id])
    @events = Score.list_tool(current_user.id, @allocation_tag_id, 'schedule_events', false, false, true)

    @can_evaluate = can?(:evaluate, ScheduleEvent, on: [@allocation_tag_id])
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

    if @schedule_event.can_change? and @schedule_event.update_attributes(schedule_event_params)
      render_schedule_event_success_json('updated')
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
    if @schedule_event.can_remove_groups?
      @schedule_event.destroy
      message = evaluative ? ['warning', t('evaluative_tools.warnings.evaluative')] : ['notice', t(:deleted, scope: [:schedule_events, :success])]
      render json: { success: true, type_message: message.first,  message: message.last }
    else
      render json: {success: false, alert: t('schedule_events.error.evaluated')}, status: :unprocessable_entity
    end
  rescue => error
    render_json_error(error, 'schedule_events.error')
  end

  def evaluate_user
    authorize! :evaluate, ScheduleEvent, {on: @allocation_tag_id = active_tab[:url][:allocation_tag_id]}
    @schedule_event = ScheduleEvent.find(params[:id])
    @ac = @schedule_event.academic_allocations.where(allocation_tag_id: @allocation_tag_id).first
    @user = User.find(params[:user_id])
    @student_id = params[:user_id]
    @score_type = params[:score_type]
    @situation = params[:situation]

    @can_evaluate = can? :evaluate, ScheduleEvent, { on: @allocation_tag_id }
    @back_to_participants = params[:back_to_participants]

    raise 'not_student' unless @user.has_profile_type_at(@allocation_tag_id)
    @acu = AcademicAllocationUser.find_one(@ac.id, params[:user_id])

  rescue CanCan::AccessDenied
    render text: t(:no_permission)
  rescue => error
    error_message = (I18n.translate!("schedule_events.error.#{error}", raise: true) rescue t("schedule_events.error.general_message"))
    render text: error_message
  end

  def participants
    raise CanCan::AccessDenied unless AllocationTag.find(@allocation_tag_id = active_tab[:url][:allocation_tag_id]).is_observer_or_responsible?(current_user.id)
    @event = ScheduleEvent.find(params[:id])
    @participants = AllocationTag.get_participants(@allocation_tag_id, { students: true })
    @situation = params[:situation]
    @group_id = params[:group_id]
    render partial: 'participants'
  end

  def presential_test_participants
    raise CanCan::AccessDenied unless AllocationTag.find(@allocation_tag_id = active_tab[:url][:allocation_tag_id]).is_observer_or_responsible?(current_user.id)

    @allocation_tag_id = active_tab[:url][:allocation_tag_id]
    @event = ScheduleEvent.find(params[:id])
    @participants = AllocationTag.get_participants(@allocation_tag_id, { students: true })

    render partial: 'presential_test_participants'
  end

  def print_presential_test
    authorize! :print_presential_test, ScheduleEvent, on: @allocation_tags_ids = params[:allocation_tags_ids]

    allocation_ids = @allocation_tags_ids.split(" ").map { |e| e.to_i  }
    allocation_tag = AllocationTag.find(allocation_ids.first)

    @course = allocation_tag.get_course
    @event = ScheduleEvent.find(params[:id])

    html = HTMLEntities.new.decode render_to_string("print_presential_test.html.haml", formats: [:html], layout: false)

    unless params[:student_id].blank?
      student = User.find(params[:student_id])
      curriculum_unit = allocation_tag.get_curriculum_unit
      coordinator = User.joins(:allocations, :profiles).where("allocations.allocation_tag_id IN (?) AND allocations.status = ? AND profiles.id = 8", allocation_tag.related, Allocation_Activated).first

      normalize_exam_header(html, student, @event, curriculum_unit, coordinator)
    end

    pictures_with_abs_path html

    pdf = WickedPdf.new.pdf_from_string(html)
    send_data(pdf, filename: "#{@event.title}.pdf", type: "application/pdf",  disposition: 'inline')
  end

  private

    def schedule_event_params
      params.require(:schedule_event).permit(:title, :description, :type_event, :start_hour, :end_hour, :place, :integrated, :content_exam, schedule_attributes: [:id, :start_date, :end_date])
    end

    def render_schedule_event_success_json(method)
      render json: {success: true, notice: t(method, scope: 'schedule_events.success')}
    end

    def curriculum_unit_name(html, name)
      remove_underscore_input_between_patterns(html, /disciplina:/i)
      html.sub!(/disciplina:/i, "Disciplina: #{name}")
    end

    def exam_name(html, exam_name)
      remove_underscore_input_between_patterns(html, /prova:/i)
      html.sub!(/prova:/i, "Prova: #{exam_name}")
    end

    def exam_date(html, date)
      remove_underscore_input_between_patterns(html, /data:/i)
      html.sub!(/data:/i, "Data: #{date}")
    end

    def place_exam(html, place)
      remove_underscore_input_between_patterns(html, /polo:/i)
      html.sub!(/polo:/i, "Polo: #{place}")
    end

    def student_name(html, student_name)
      remove_underscore_input_between_patterns(html, /nome do\(a\) aluno\(a\):/i)
      html.sub!(/nome do\(a\) aluno\(a\):/i, "Nome do(a) aluno(a): #{student_name}")
    end

    def coordinator_name(html, coordinator_name)
      remove_underscore_input_between_patterns(html, /coordenador\(a\) da disciplina:/i)
      html.sub!(/coordenador\(a\) da disciplina:/i, "Coordenador(a) da disciplina: #{coordinator_name}")
    end

    def normalize_exam_header(html, student, event, curriculum_unit, coordinator)
      curriculum_unit_name html, curriculum_unit.name
      coordinator_name html, coordinator.name
      place_exam html, event.place
      exam_name html, event.title
      exam_date html, event.schedule.end_date
      student_name html, student.name
    end

    def remove_underscore_input_between_patterns(html, pattern)
      initial_match = html.match(pattern)
      fim_match = initial_match.post_match.match(/<\/span>/) unless initial_match.nil?
      removed_underscore = fim_match.pre_match.gsub!(/_/, '') unless fim_match.nil?
      html.sub!(fim_match.pre_match, removed_underscore) unless initial_match.nil? || fim_match.nil? || removed_underscore.nil?
    end

    def pictures_with_abs_path(html)
      html.gsub!(/(href|src)=(['"])\/([^\"']*|[^"']*)['"]/i, '\1=\2' + "#{Rails.root}/" + '\3\2')
    end
end
