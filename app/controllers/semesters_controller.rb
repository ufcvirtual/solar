class SemestersController < ApplicationController
  layout false, except: :index 

  # GET /semesters
  def index
    # raise "#{params}"
    authorize! :index, Semester

    if [params[:period], params[:course_id], params[:curriculum_unit_id]].delete_if(&:blank?).empty?
      @semesters = []
    else
      p = {}
      p[:course_id] = params[:course_id] if params[:course_id].present?
      p[:uc_id] = params[:curriculum_unit_id] if params[:curriculum_unit_id].present?
      p[:period] = params[:period] if params[:period].present?

      # [active, all, year]
      if params[:period] == "all"
        if p.has_key?(:course_id) or p.has_key?(:uc_id)
          @semesters = Semester.all_by_uc_or_course(p)
        else
          @semesters = []
        end
      else
        @semesters = Semester.all_by_period(p) # semestres do período informado ou ativos
      end
    end

    if params[:combobox]
      render json: { 'html' => render_to_string(partial: 'select_semester.html', locals: { semesters: @semesters }) }
    else
      render layout: false
    end
  end

  # GET /semesters/1
  ## verificar necessidade desse metodo
  def show
    authorize! :index, Semester

    @semester = Semester.find(params[:id])
  end

  # GET /semesters/new
  # GET /semesters/new.json
  def new
    authorize! :create, Semester

    @semester = Semester.new
    @semester.build_offer_schedule
    @semester.build_enrollment_schedule

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @semester }
    end
  end

  # GET /semesters/1/edit
  def edit
    authorize! :update, Semester
    @semester = Semester.find(params[:id])
  end

  # POST /semesters
  # POST /semesters.json
  def create
    authorize! :create, Semester
    @semester = Semester.new params[:semester]

    if @semester.save
      render json: {success: true, notice: t(:created, scope: [:semesters, :success]), semester: {start: @semester.offer_schedule.start_date.year, end: @semester.offer_schedule.end_date.year}}
    else
      render :new
    end
  end

  # PUT /semesters/1
  # PUT /semesters/1.json
  def update
    authorize! :update, Semester
    @semester = Semester.find(params[:id])

    if @semester.update_attributes(params[:semester])
      render json: {success: true, notice: t(:updated, scope: [:semesters, :success]), semester: {start: @semester.offer_schedule.start_date.year, end: @semester.offer_schedule.end_date.year}}
    else
      render :edit
    end
  end

  # DELETE /semesters/1
  # DELETE /semesters/1.json
  def destroy
    @semester = Semester.find(params[:id])
    authorize! :destroy, Semester

    if ((@semester.offers.empty? or @semester.offers.map(&:groups).empty?) and @semester.destroy)
      render json: {success: true, notice: t(:deleted, scope: [:semesters, :success])}
    else
      render json: {success: false, alert: t(:deleted, scope: [:semesters, :error])}, status: :unprocessable_entity
    end
  end

end
