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
      verify_management
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
    @accessibility =  params[:accessibility]

    # if @course.has_exam_header && @course.is_uab_course?
    #   @course.header_exam = @course.default_header_uab
    # end

    if @event.content_exam.blank?
      render text: t("schedule_events.error.no_content")
    else
      html = HTMLEntities.new.decode render_to_string("print_presential_test.html.haml", formats: [:html], layout: false)

      unless @allocation_tags_ids.size > 1
        coord_profiles = (YAML::load(File.open('config/global.yml'))[Rails.env.to_s]['coord_profiles'] rescue nil)
        coord = User.joins(:allocations).where("allocations.allocation_tag_id IN (?) AND allocations.status = ? AND allocations.profile_id IN (?)", ats, Allocation_Activated, coord_profiles.split(',')).first unless coord_profiles.blank?

        prof_profiles = (YAML::load(File.open('config/global.yml'))[Rails.env.to_s]['prof_profiles'] rescue nil)
        profs = User.joins(:allocations).where("allocations.allocation_tag_id IN (?) AND allocations.status = ? AND allocations.profile_id IN (?)", ats, Allocation_Activated, prof_profiles.split(',')).distinct unless prof_profiles.blank?

        tutor_profiles = (YAML::load(File.open('config/global.yml'))[Rails.env.to_s]['tutor_profiles'] rescue nil)
        tutors = User.joins(:allocations).where("allocations.allocation_tag_id IN (?) AND allocations.status = ? AND allocations.profile_id IN (?)", ats, Allocation_Activated, tutor_profiles.split(',')).distinct unless tutor_profiles.blank?
      end

      student = User.find(params[:student_id]) unless params[:student_id].blank?
      enrollment = Allocation.where(user_id: params[:student_id], allocation_tag_id: @allocation_tags_ids.first, status: 1).first.enrollment unless params[:student_id].blank?

      normalize_exam_header(html, student, enrollment, profs, tutors, @event, allocation_tag.get_curriculum_unit, @course.name, coord)

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

    def normalize_exam_header(html, student, enrollment, profs, tutors, event, curriculum_unit, course_name, coord)
           fill_field_info html, /curso:(\s*\n*\t*(&nbsp;)*)_*/i, "Curso: <b>#{course_name}</b>" unless course_name.blank?
      fill_field_info html, /disciplina:(\s*\n*\t*(&nbsp;)*)_*/i, "Disciplina: <b>#{curriculum_unit.code} - #{curriculum_unit.name}</b>" unless curriculum_unit.nil?
      # fill_field_info html, /(coordenador\(a\)(\s*\n*\t*(&nbsp;)*)do(\s*\n*\t*(&nbsp;)*)curso:|coordenador\(a\)(\s*\n*\t*(&nbsp;)*)da(\s*\n*\t*(&nbsp;)*)curso:|coordenador:(\s*\n*\t*(&nbsp;)*)coordenador\(a\)(\s*\n*\t*(&nbsp;)*)de(\s*\n*\t*(&nbsp;)*)curso:)/i, "Coordenador(a) do curso: #{coord.name}<br>" unless coord.nil?
      fill_field_info html, /(nome(\s*\n*\t*(&nbsp;)*)do\(a\)(\s*\n*\t*(&nbsp;)*)aluno\(a\):(\s*\n*\t*(&nbsp;)*)|nome(\s*\n*\t*(&nbsp;)*)do(\s*\n*\t*(&nbsp;)*)aluno:|aluno:)_*/i, "Nome do(a) aluno(a): <b>#{student.name}</b>" unless student.nil?
      fill_field_info html, /(matricula:(\s*\n*\t*(&nbsp;)*)|matrícula:(\s*\n*\t*(&nbsp;)*))_*/i, "Matrícula: <b>#{enrollment}</b>" unless enrollment.blank?
      unless event.blank?
        fill_field_info html, /prova:(\s*\n*\t*(&nbsp;)*)_*/i, "Prova: <b>#{event.title}</b>"
        fill_field_info html, /data:(\s*\n*\t*(&nbsp;)*)_*/i, "Data: <b>#{event.get_date}</b>"
        fill_field_info html, /polo:(\s*\n*\t*(&nbsp;)*)_*/i, "Polo: <b>#{event.place}</b>"
      end
      profs.each { |prof| fill_field_info html, /(professor\(a\)(\s*\n*\t*(&nbsp;)*)titular:(\s*\n*\t*(&nbsp;)*)|professor(\s*\n*\t*(&nbsp;)*)titular:(\s*\n*\t*(&nbsp;)*)|professor:(\s*\n*\t*(&nbsp;)*)|coordenador\(a\)(\s*\n*\t*(&nbsp;)*)de(\s*\n*\t*(&nbsp;)*)disciplina:(\s*\n*\t*(&nbsp;)*)|coordenador\(a\)(\s*\n*\t*(&nbsp;)*)da(\s*\n*\t*(&nbsp;)*)disciplina:(\s*\n*\t*(&nbsp;)*))/i, "Professor(a) da disciplina: #{prof.name}<br>"  } unless profs.blank?
      tutors.each { |tutor| fill_field_info html, /(tutor\(a\)(\s*\n*\t*(&nbsp;)*)à(\s*\n*\t*(&nbsp;)*)distância:(\s*\n*\t*(&nbsp;)*)|tutor(\s*\n*\t*(&nbsp;)*)à(\s*\n*\t*(&nbsp;)*)distância:(\s*\n*\t*(&nbsp;)*)|tutor:(\s*\n*\t*(&nbsp;)*))/i, "Tutor(a) à distância: #{tutor.name}<br>"  } unless tutors.blank?
    end


    def pictures_with_abs_path(html)
      html.gsub!(/(href|src)=(['"])\/([^\"']*|[^"']*)['"]/i, '\1=\2' + "#{Rails.root}/" + '\3\2')
    end

    def verify_management
      allocation_tag_ids = params[:allocation_tags_ids]
      allocation_tag_ids.split(" ").each do |allocation_tag_id|

        unless ScheduleEvent.joins(:academic_allocations).where(type_event: 1, academic_allocations: {allocation_tag_id: allocation_tag_id.to_i}).blank?
          management_activities(allocation_tag_id.to_i)
        end

      end

    end

    def management_activities(allocation_tag_id)
      academic_allocations = AcademicAllocation.where(allocation_tag_id: allocation_tag_id).where("academic_tool_type NOT IN ('SupportMaterialFile', 'Bibliography', 'Notification', 'LessonModule')")

      at = AllocationTag.find(allocation_tag_id.to_i)

      total_hours_of_curriculum_unit = at.group.nil? ? at.offer.curriculum_unit.working_hours : at.group.offer.curriculum_unit.working_hours
      quantity_activities = 0
      quantity_used_hours = 0

      acad_alloc_not_event = []
      acad_alloc_event = []

      acad_alloc_to_save = []

      academic_allocations.each do |academic_allocation|
        academic_tool = academic_allocation.academic_tool

        if academic_allocation.academic_tool_type == 'ScheduleEvent' #&& academic_tool.integrated == true

          if academic_tool.type_event == Presential_Test # eventos tipo 1 ou 2 chamada
            academic_allocation.evaluative = true
            academic_allocation.final_weight = 60
            academic_allocation.frequency = true
            academic_allocation.max_working_hours = BigDecimal.new(2)

            if academic_tool.title == "Prova Presencial: AF - 1ª chamada" || academic_tool.title == "Prova Presencial: AF - 2ª chamada" # se Avaliação Final
              academic_allocation.final_exam = true
              academic_allocation.frequency = false
              academic_allocation.max_working_hours = BigDecimal.new(0)
            end

            if academic_tool.title == "Prova Presencial: AP - 2ª chamada" || academic_tool.title == "Prova Presencial: AF - 2ª chamada" # se 2 chamada, então deve ser equivalente a 1 chamada

              equivalent = ScheduleEvent.joins(:academic_allocations).where(title: academic_tool.title.sub("2", "1"), academic_allocations: {equivalent_academic_allocation_id: nil, allocation_tag_id: allocation_tag_id.to_i})

              unless equivalent.blank?
                academic_allocation.equivalent_academic_allocation_id = equivalent[0].academic_allocations[0].id
                academic_allocation.max_working_hours = BigDecimal.new(0)
              end

            end

          end

          unless [Presential_Test, Recess, Holiday, Other].include?(academic_tool.type_event) # demais eventos exceto: recesso, feriado e outros
            academic_allocation.frequency = true
            academic_allocation.max_working_hours = BigDecimal.new(2)
          end

          acad_alloc_event << academic_allocation

        else # atividades que não são eventos
          academic_allocation.evaluative = true
          academic_allocation.final_weight = 40
          academic_allocation.frequency = true
          quantity_activities += 1

          acad_alloc_not_event << academic_allocation
        end

      end

      acad_alloc_event.each do |event|
        if event.final_exam == false || event.equivalent_academic_allocation_id.nil?
          quantity_used_hours += event.max_working_hours.to_i
        end
      end

      remaining_hours = total_hours_of_curriculum_unit - quantity_used_hours
      resto = remaining_hours % quantity_activities rescue 0
      hours_per_activity = remaining_hours / quantity_activities rescue 0

      acad_alloc_not_event.each{ |ac_all| ac_all.max_working_hours = BigDecimal.new(hours_per_activity)}

      if resto != 0
        acad_alloc_not_event.last.max_working_hours += BigDecimal.new(resto)
      end

      acad_alloc_to_save.concat(acad_alloc_event.sort_by!{|all| all.academic_tool.title}).concat(acad_alloc_not_event)

      unless acad_alloc_to_save.blank?
        ActiveRecord::Base.transaction do
          acad_alloc_to_save.each do |acad_alloc|
            acad_alloc.save!
          end
        end
      end

    end

end
