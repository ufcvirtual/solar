class LessonsController < ApplicationController

  layout false, :except => [:index]

  include EditionHelper
  include FilesHelper

  before_filter :prepare_for_group_selection, :only => [:index, :download_files]
  before_filter :curriculum_data, :except => [:list, :download_files, :extract_files, :new, :create, :edit, :update]

  load_and_authorize_resource :except => [:index, :list, :download_files, :new, :create, :edit, :update, :show]

  def show
    render :layout => 'lesson_frame'
  end

  def show_header
    @lessons = lessons_to_open
    render :layout => 'lesson'
  end

  def show_content
    render :layout => 'lesson'
  end

  def index
    authorize! :index, Lesson
    @lessons = lessons_to_open(params[:allocation_tags_ids])
    render :layout => false if params[:allocation_tags_ids]
  end

  # listagem do cadastro de aulas  
  def list
    allocation_tags    = params[:allocation_tags_ids]
    @what_was_selected = params[:what_was_selected]

    begin
      authorize! :list, Lesson, :on => [allocation_tags]
      @allocation_tags = allocation_tags.collect{ |id| AllocationTag.find(id) }
      # comentei até ver chamada ajax
      #allocation_tags = allocation_tags.first unless allocation_tags.count > 1 # agiliza na consulta caso seja apenas um id
      # @lesson_modules = LessonModule.find_all_by_allocation_tag_id(allocation_tags, order: "allocation_tag_id")
    rescue
      respond_to do |format|
        format.html { render :nothing => true, :status => 500  }
      end
    end

  end

  # GET /lessons/new
  # GET /lessons/new.json
  def new
    @lesson = Lesson.new
  end

  # POST /lessons
  # POST /lessons.json
  def create
    module_id = params[:lesson_module_id]
    allocation_tags_ids = params[:allocation_tags_ids].split(" ")

    begin
      authorize! :create, Lesson, :on => allocation_tags_ids

      order = LessonModule.maximum(:order, :conditions => ['id > ?', module_id]).to_i + 1
      lesson = Lesson.new(params[:lesson])

      Lesson.transaction do
        schedule = Schedule.create!(:start_date => params["start_date"], :end_date => params["end_date"])
        Lesson.create!(:name => lesson.name, 
                     :description => lesson.description, 
                     :address => lesson.address,
                     :lesson_module_id => module_id.to_i,
                     :order => order,
                     :status => lesson.status,
                     :type_lesson => lesson.type_lesson,
                     :user_id => current_user.id,
                     :schedule_id => schedule.id)
      end

      respond_to do |format|
        format.html { render :list, :status => 200 }        
      end

    rescue
      respond_to do |format|
        format.html { render :new } #, :status => 500 }
      end
    end

  end

  # GET /lessons/1/edit
  def edit
    @lesson = Lesson.find(params[:id])

    puts "\n\n\n*** params: #{@lesson}\n\n"
  end

  # PUT /lessons/1
  # PUT /lessons/1.json
  def update
    respond_to do |format|
      if @lesson.update_attributes(params[:lesson])
        format.html { render :list }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    @lesson = Lesson.find(params[:id])

    begin
      #authorize! :destroy, @lesson
      raise "error" unless @lesson.destroy # exclui aula (apenas se em teste)
      respond_to do |format|
        format.html{ render :nothing => true, :status => 200 }
      end
    rescue
      respond_to do |format|
        format.html{ render :nothing => true, :status => 500 }
      end
    end
  end

  def download_files
    authorize! :download_files, Lesson, :on => [params[:allocation_tags_ids]].flatten.collect{|id| id.to_i}

    unless params[:lessons_ids].empty?

      lessons_ids     = params[:lessons_ids].split(",").flatten
      all_files_paths = lessons_ids.collect{ |lesson_id| File.join(Rails.root.to_s, 'media', 'lessons', lesson_id) }
      lessons_names   = lessons_ids.collect{ |lesson_id| Lesson.find(lesson_id).name }

      zip_file_path   = compress(:under_path => all_files_paths, :folders_names => lessons_names)
      zip_file_name   = zip_file_path.split("/").last

      redirect        = request.referer.nil? ? root_url(:only_path => false) : request.referer
      download_file(redirect, zip_file_path, zip_file_name)

    else
      flash[:alert] = t(:must_select_lessons, :scope => [:lessons, :notifications])
      redirect_to list_lessons_url(:allocation_tag_id => params[:allocation_tags_ids])
    end

  end

  def extract_files
    path_zip_file = File.join(Lesson::FILES_PATH, params[:id], [params[:file], params[:extension]].join('.'))
    destination   = File.join(Lesson::FILES_PATH, params[:id])

    respond_to do |format|
      format.json { render json: {success: extract(path_zip_file, destination)} }
    end
  end

  private

    def curriculum_data
      @curriculum_unit = CurriculumUnit.find(params[:curriculum_unit_id] || active_tab[:url]['id'])
    end

    def lessons_to_open(allocation_tags_ids = nil)
      allocation_tags_ids = allocation_tags_ids || AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])
      Lesson.to_open(allocation_tags_ids.join(", "))
    end
end
