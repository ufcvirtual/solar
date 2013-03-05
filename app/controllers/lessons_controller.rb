class LessonsController < ApplicationController

  layout false, :except => [:index]

  include EditionHelper
  include FilesHelper
  include LessonFileHelper

  before_filter :prepare_for_group_selection, only: [:index, :download_files]
  before_filter :curriculum_data, except: [:new, :create, :edit, :update, :list, :download_files, :extract_files, :order]

  def index
    authorize! :index, Lesson

    @lessons = lessons_to_open(params[:allocation_tags_ids])
    render layout: false if params[:allocation_tags_ids]
  end

  # GET /lessons/:id
  def show
    authorize! :show, Lesson, {on: [@curriculum_unit.allocation_tag.id], read: true} # apenas para quem faz parte da turma

    @lesson = Lesson.find(params[:id])
    render layout: 'lesson_frame'
  end

  # GET /lessons/new
  # GET /lessons/new.json
  def new
    authorize! :new, Lesson

    @lesson_module = LessonModule.find(params[:lesson_module_id]) if params[:lesson_module_id].present?
    @lesson = Lesson.new
  end

  # POST /lessons
  # POST /lessons.json
  def create
    authorize! :create, Lesson, on: params[:allocation_tags_ids].split(" ")

    begin
      params[:lesson][:lesson_module_id] = params[:lesson_module_id]
      params[:lesson][:user_id] = current_user.id
      params[:lesson][:order] = Lesson.where(lesson_module_id: params[:lesson_module_id]).maximum(:order).to_i + 1

      @lesson = Lesson.new(params[:lesson])
      Lesson.transaction do
        @lesson.schedule = Schedule.create!(start_date: params[:start_date], end_date: params[:end_date])
        @lesson.save!
      end

      manage_file = false
      if @lesson.type_lesson == Lesson_Type_File
        manage_file = true 
        file = Lesson::FILES_PATH.join(@lesson.id.to_s).to_s
        Dir.mkdir(file) unless File.exist?(file)
        @files = directory_hash(file, @lesson.name).to_json
        @folders = directory_hash(file, @lesson.name, false).to_json
      end

      respond_to do |format|
        format.html { render (manage_file ? {template: "/lesson_files/index", layout: false} : {nothing: true}), status: 200 }
      end

    rescue
      respond_to do |format|
        format.html { render :new }
      end
    end # rescue
  end

  # GET /lessons/1/edit
  def edit
    authorize! :update, Lesson, on: params[:allocation_tags_ids].split(" ") # para pode editar percisa ter permissao para salvar

    @lesson_modules = LessonModule.where(allocation_tag_id: params[:allocation_tags_ids].split(' '))
    @lesson = Lesson.find(params[:id])
  end

  # PUT /lessons/1
  # PUT /lessons/1.json
  def update
    authorize! :update, Lesson, on: params[:allocation_tags_ids].split(" ")

    @lesson_modules = LessonModule.where(allocation_tag_id: params[:allocation_tags_ids].split(' '))
    @lesson = Lesson.find(params[:id])
    error = false
    begin
      Lesson.transaction do
        @lesson.update_attributes!(params[:lesson])
        @lesson.schedule.update_attributes!(start_date: params[:start_date], end_date: params[:end_date])
      end
 
    rescue
      error = true
      @schedule_error = @lesson.schedule.errors.full_messages[0] unless @lesson.schedule.valid?
    end

    respond_to do |format|
      if error
        format.html { render :edit }
      else
        format.html { render nothing: true }
      end # else
    end # end respond
  end

  def destroy
    @lesson = Lesson.find(params[:id])
    authorize! :destroy, Lesson, on: params[:allocation_tags_ids].split(" ")

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

  # cadastro de aulas
  def list
    allocation_tags    = params[:allocation_tags_ids]
    @what_was_selected = params[:what_was_selected]

    begin
      authorize! :list, Lesson, on: [allocation_tags].flatten
      @allocation_tags = AllocationTag.where(id: allocation_tags)
    rescue Exception => error
      respond_to do |format|
        format.html { render nothing: true, status: 500 }
      end
    end
  end

  def show_header
    @lessons = lessons_to_open
    render layout: 'lesson'
  end

  def show_content
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

  ## PUT lessons/:id/order/:change_id
  def order
    begin
      authorize! :order, Lesson
      success = false

      l1, l2 = Lesson.find(params[:id], params[:change_id])
      Lesson.transaction do
        l1.order, l2.order = l2.order, l1.order
        l1.save!
        l2.save!
      end
      success = true
    rescue CanCan::AccessDenied
      status = :unauthorized
    rescue
      status = 500
    end

    respond_to do |format|
      if success
        format.json { render json: {success: true} }
      else
        format.json { render nothing: true, status: status }
      end
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
