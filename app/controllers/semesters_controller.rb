class SemestersController < ApplicationController
  layout false, except: :index 

  # GET /semesters
  # GET /semesters.json
  def index
    authorize! :index, Semester

    # como ficará a ordenação?

    if [params[:period], params[:course_id], params[:curriculum_unit_id]].delete_if(&:blank?).empty?
      @semesters = []
    else
      query = []
      query << "offers.course_id = #{params[:course_id]}" unless params[:course_id].blank?
      query << "offers.curriculum_unit_id = #{params[:curriculum_unit_id]}" unless params[:curriculum_unit_id].blank?

      # [active, all, year]
      if params[:period] == "all"
        if query.empty?
          @semesters = Semester.all # o que fazer neste caso?
        else
          @semesters = Semester.joins(:offers).where(query.join(" AND ")).uniq
        end
      else
        begin
          year = Date.parse("#{params[:period]}-01-01").year
        rescue
          year = Date.today.year
        end

        current_semesters = Semester.joins("LEFT JOIN offers ON offers.semester_id = semesters.id").currents(year).where(query.join(" AND "))
        query << "semester_id NOT IN (#{current_semesters.map(&:id).join(',')})" unless current_semesters.empty? # retirando semestres ja listados
        semesters_of_current_offers = Offer.currents(year).where(query.join(" AND ")).map(&:semester)
        @semesters = (current_semesters + semesters_of_current_offers).uniq
      end
    end

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
