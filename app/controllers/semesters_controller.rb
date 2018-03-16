class SemestersController < ApplicationController

  include SysLog::Actions

  layout false, except: :index

  # GET /semesters
  def index
    authorize! :index, Semester unless params[:combobox]
    @type_id = params[:type_id].to_i

    if [params[:period], params[:course_id], params[:curriculum_unit_id]].delete_if(&:blank?).empty?
      @semesters = []
    else
      p = {type_id: @type_id}
      p[:course_id] = params[:course_id]          if params[:course_id].present?
      p[:uc_id]     = params[:curriculum_unit_id] if params[:curriculum_unit_id].present?
      p[:period]    = params[:period]             if params[:period].present?

      # [active, all, year]
      if params[:period] == "all"
        if p.has_key?(:course_id) or p.has_key?(:uc_id)
          @semesters = Semester.all_by_uc_or_course(p, params[:combobox])
        else
          @semesters = []
        end
      else
        @semesters = Semester.all_by_period(p, params[:combobox]) # semestres do período informado ou ativos
      end
    end

    if params[:combobox]
      render json: { 'html' => render_to_string(partial: 'select_semester.html', locals: { semesters: @semesters }) }
    else
      @allocation_tags_ids = current_user.allocation_tags_ids_with_access_on([:update, :destroy], "offers").join(" ")
      render layout: false
    end
  end

  # GET /semesters/new
  def new
    authorize! :create, Semester
    @type_id = params[:type_id].to_i

    start_date, end_date = Date.today - 1.month, Date.today + 1.month

    @semester = Semester.new
    @semester.build_offer_schedule start_date: start_date, end_date: end_date
    @semester.build_enrollment_schedule start_date: start_date
  end

  # GET /semesters/1/edit
  def edit
    authorize! :update, Semester

    @type_id = params[:type_id].to_i
    @semester = Semester.find(params[:id])
  end

  # POST /semesters
  def create
    authorize! :create, Semester

    @semester = Semester.new semester_params
    if @semester.save
      render_semester_success_json('created')
    else
      @type_id = @semester.type_id
      render :new
    end
  end

  # PUT /semesters/1
  def update
    ats = RelatedTaggable.where(semester_id: params[:id]).pluck(:offer_at_id)
    if ats.empty?
      authorize! :update, Semester
    else
      authorize! :update, Semester, { on: ats }
    end

    @semester = Semester.find(params[:id])
    update_offer_activities_from_semester(@semester)

    if @semester.update_attributes(semester_params)
      render_semester_success_json('updated')
    else
      @type_id = @semester.type_id
      render :edit
    end
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unprocessable_entity
  end

  # DELETE /semesters/1
  def destroy
    ats = RelatedTaggable.where(semester_id: params[:id]).pluck(:offer_at_id)
    if ats.empty?
      authorize! :destroy, Semester
    else
      authorize! :destroy, Semester, { on: ats }
    end

    @semester = Semester.find(params[:id])

    if @semester.destroy
      render_semester_success_json('deleted')
    else
      render json: {success: false, alert: t('semesters.error.deleted')}, status: :unprocessable_entity
    end
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unprocessable_entity
  end

  private

    def semester_params
      params.require(:semester).permit(:type_id, :name, offer_schedule_attributes: [:id, :start_date, :end_date, :_destroy], enrollment_schedule_attributes: [:id, :start_date, :end_date, :_destroy])
    end

    def render_semester_success_json(method)
      render json: {success: true, notice: t(method, scope: 'semesters.success'), semester: {start: @semester.offer_schedule.start_date.year, end: @semester.offer_schedule.end_date.year}}
    end

    def update_offer_activities_from_semester(semester)

      param_off_start_date = params[:semester][:offer_schedule_attributes][:start_date].blank? ? nil : Date.parse(params[:semester][:offer_schedule_attributes][:start_date])
      param_off_end_date = params[:semester][:offer_schedule_attributes][:end_date].blank? ? nil : Date.parse(params[:semester][:offer_schedule_attributes][:end_date])

      if (param_off_end_date != nil && param_off_start_date != nil)

        offers = Offer.where(semester_id: semester.id)

        offers.each do |off|

          group_id = Group.where(offer_id: off.id).pluck(:id)
          allocation_tag_id = AllocationTag.where(group_id: group_id).pluck(:id)
          academic_allocation = AcademicAllocation.where(allocation_tag_id: allocation_tag_id)
          related_users_emails = Allocation.where(allocation_tag_id: allocation_tag_id).map{|al| al.user.email}
          activities_to_email = {}
          activities_to_save = []
          Struct.new('Activity_Object',:name, :start_date, :end_date)

          academic_allocation.each do |al|
            act = al.academic_tool

            if ['Assignment', 'Discussion', 'ChatRoom', 'Notification', 'ScheduleEvent'].include? al.academic_tool_type

              # se tentou mover o periodo total da oferta para antes do inicio ou depois do final da atividade
              if (param_off_start_date < act.schedule.start_date && param_off_end_date < act.schedule.start_date) || (param_off_start_date > act.schedule.end_date && param_off_end_date > act.schedule.end_date )
                raise "A atividade #{al.academic_tool_type} - #{act.name} não pode ser alterada para este período de oferta!"
              end

              if act.schedule.start_date < param_off_start_date
                act.schedule.start_date = param_off_start_date
              end

              if act.schedule.end_date > param_off_end_date
                act.schedule.end_date = param_off_end_date
              end

              if act.schedule.changed?
                  struct = Struct::Activity_Object.new(act.name, act.schedule.start_date.to_s, act.schedule.end_date.to_s)
                  activities_to_email[Object.const_get(al.academic_tool_type).model_name.human] ||= []
                  activities_to_email[Object.const_get(al.academic_tool_type).model_name.human] << struct
                  activities_to_save << act
              end

            end

            if ['Webconference'].include? al.academic_tool_type

              if act.initial_time < param_off_start_date
                act.initial_time = Time.new(param_off_start_date.year, param_off_start_date.month, param_off_start_date.day, act.initial_time.hour, act.initial_time.min, act.initial_time.sec)
              end

              if act.initial_time > param_off_end_date
                act.initial_time = Time.new(param_off_end_date.year, param_off_end_date.month, param_off_end_date.day, act.initial_time.hour, act.initial_time.min, act.initial_time.sec)
              end

              if act.changed?
                struct = Struct::Activity_Object.new(act.title, act.initial_time.to_date.to_s, act.initial_time.to_date.to_s)
                activities_to_email[Object.const_get(al.academic_tool_type).model_name.human] ||= []
                activities_to_email[Object.const_get(al.academic_tool_type).model_name.human] << struct
                activities_to_save << act
              end

            end

            if ['LessonModule'].include? al.academic_tool_type
              lessons = Lesson.where(lesson_module_id: act.id)

              lessons.each do |lesson|

                # se tentou mover o periodo total da oferta para antes do inicio ou depois do final da atividade
                if (param_off_start_date < lesson.schedule.start_date && param_off_end_date < lesson.schedule.start_date) || (param_off_start_date > lesson.schedule.end_date && param_off_end_date > lesson.schedule.end_date )
                  activities_to_save = []
                  activities_to_email = {}
                  raise "A atividade #{al.academic_tool_type} - #{act.name} não pode ser alterada para este período de oferta!"
                end

                if lesson.schedule.start_date < param_off_start_date
                  lesson.schedule.start_date = param_off_start_date
                end

                if lesson.schedule.end_date != nil && lesson.schedule.end_date  > param_off_end_date
                  lesson.schedule.end_date = param_off_end_date
                end

                if lesson.schedule.changed?
                  struct = Struct::Activity_Object.new(lesson.name, lesson.schedule.start_date.to_s, lesson.schedule.end_date.to_s)
                  activities_to_email[Object.const_get(al.academic_tool_type).model_name.human] ||= []
                  activities_to_email[Object.const_get(al.academic_tool_type).model_name.human] << struct
                  activities_to_save << lesson
                end

              end

            end

            if ['Exam'].include? al.academic_tool_type

              difference_in_days = (act.schedule.end_date - act.schedule.start_date).to_i

              # se tentou mover o periodo total da oferta para antes do inicio da atividade
              if (act.schedule.start_date < param_off_start_date && act.schedule.end_date < param_off_start_date) || (act.schedule.end_date > param_off_end_date && act.schedule.start_date > param_off_end_date)
                raise "A atividade #{al.academic_tool_type} - #{act.name} não pode ser alterada para este período de oferta!"
              end

              if (act.schedule.start_date < param_off_start_date && difference_in_days == 0 )
                act.schedule.start_date = param_off_start_date
                act.schedule.end_date = param_off_start_date
              elsif act.schedule.start_date < param_off_start_date
                act.schedule.start_date = param_off_start_date
              end

              if (act.schedule.end_date > param_off_end_date && difference_in_days == 0)
                act.schedule.end_date = param_off_end_date
                act.schedule.start_date = param_off_end_date
              elsif act.schedule.end_date > param_off_end_date
                act.schedule.end_date = param_off_end_date
              end

              if act.changed?
                struct = Struct::Activity_Object.new(act.name, act.schedule.start_date.to_s, act.schedule.end_date.to_s)
                activities_to_email[al.academic_tool_type] ||= []
                activities_to_email[al.academic_tool_type] << act
                activities_to_save << act
              end

            end

          end

          unless activities_to_save.blank?
            ActiveRecord::Base.transaction do
              activities_to_save.each do |activity|
                activity.save
              end
            end
          end

          unless activities_to_email.blank?
            Notifier.send_mail(related_users_emails, "Alteração do Período da(s) Atividade(s)", email_template(activities_to_email), []).deliver
          end

        end

      end

    end

    def msg_template(activities)
      html = ""
      activities.each do |key, value|
        value.each do |object|
          if key == "Webconference"
            html << "<p>Atividade: #{key} - #{object.name} foi alterada para #{object.start_date}</p>"
          else
            html << "<p>Atividade: #{key} - #{object.name} foi alterada para #{object.start_date} à #{object.end_date}</p>"
          end
        end
      end
      html
    end

    def email_template(activities)
      %{#{msg_template(activities)}}
    end

end
