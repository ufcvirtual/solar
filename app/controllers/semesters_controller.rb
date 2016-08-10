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

end
