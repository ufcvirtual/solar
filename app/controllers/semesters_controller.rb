class SemestersController < ApplicationController
  layout false, except: :index 

  # GET /semesters
  # GET /semesters.json
  def index
    authorize! :index, Semester

    query = []
    query << "offers.course_id = #{params[:course_id]}" if params.include?(:course_id)
    query << "offers.curriculum_unit_id = #{params[:curriculum_unit_id]}" if params.include?(:curriculum_unit_id)

    offer_semesters = Semester.joins(offers: :period_schedule).where(query.join(" AND ")).where("schedules.end_date >= current_date") # olhando pras ofertas
    semesters       = Semester.joins(:offers, :offer_schedule).uniq.where(query.join(" AND ")).where("schedules.end_date >= current_date") # olhando pros semestres

    @semesters = (offer_semesters + semesters).uniq

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @semesters }
    end
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
    @semester = Semester.new(params[:semester])

    if @semester.save
      render nothing: true
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
      render nothing: true
    else
      render :edit
    end
  end

  # DELETE /semesters/1
  # DELETE /semesters/1.json
  def destroy
    @semester = Semester.find(params[:id])
    authorize! :destroy, Semester

    respond_to do |format|
      if ((@semester.offers.empty? or @semester.offers.map(&:groups).empty?) and @semester.destroy)
        format.html { redirect_to semesters_url, notice: 'Semester was successfully deleted.' }
      else
        format.html { redirect_to semesters_url, alert: "Semester can't be deleted." }
      end
      format.json { head :no_content }
    end
  end

end
