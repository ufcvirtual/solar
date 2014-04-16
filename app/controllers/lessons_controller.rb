class LessonsController < ApplicationController

  layout false, except: [:index]

  require 'fileutils'

  include EditionHelper
  include FilesHelper
  include LessonFileHelper
  include LessonsHelper

  before_filter :prepare_for_group_selection, only: [:index, :download_files]
  before_filter :curriculum_data, except: [:new, :create, :edit, :update, :list, :download_files, :order, :destroy]

  def index
    authorize! :index, Lesson

    @lessons = lessons_to_open(params[:allocation_tags_ids])
    render layout: false if params[:allocation_tags_ids]
  end

  def list
    allocation_tags    = params[:allocation_tags_ids]

    begin
      authorize! :list, Lesson, on: [allocation_tags].flatten
      @allocation_tags = AllocationTag.where(id: allocation_tags)
      @allocation_tags_ids  = @allocation_tags.map(&:id)
      @academic_allocations = AcademicAllocation.select("DISTINCT on (academic_tool_id) *").where(academic_tool_type: 'LessonModule').where(allocation_tag_id: @allocation_tags_ids)
    rescue
      render nothing: true, status: 500
    end
  end

  # GET /lessons/:id
  def show
    unless @curriculum_unit
      render text: t(:curriculum_unit_not_selected, scope: :lessons), status: :not_found
    else
      authorize! :show, Lesson, {on: [@curriculum_unit.allocation_tag.id], read: true} # apenas para quem faz parte da turma

      @all_lessons = lessons_to_open
      @lessons = @all_lessons.select { |l| not l.closed? } # user can access

      @lesson = Lesson.find(params[:id])
      render layout: 'lesson'
    end
  end

  # GET /lessons/new
  # GET /lessons/new.json
  def new
    authorize! :new, Lesson

    @lesson_module = LessonModule.find(params[:lesson_module_id]) if params[:lesson_module_id].present?
    @groups = @lesson_module.groups
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
      @lesson_module = LessonModule.find(params[:lesson_module_id]) if params[:lesson_module_id].present?

      @lesson = Lesson.new(params[:lesson])
     
      Lesson.transaction do
        @lesson.schedule = Schedule.create!(start_date: params[:start_date], end_date: params[:end_date])
        @lesson.save!
      end

      
      @lesson.type_lesson == Lesson_Type_File ? files_and_folders(@lesson) : manage_file = false

      render ((manage_file != false) ? {template: "lesson_files/index"} : {json: {success: true, notice: t(:created, scope: [:lessons, :success])}})
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue Exception 
      @groups  = @lesson_module.groups 
      render :new
    end # rescue
  end

  # GET /lessons/1/edit
  def edit
    authorize! :update, Lesson, on: params[:allocation_tags_ids].split(" ") # para pode editar percisa ter permissao para salvar


    @lesson_modules = LessonModule.select("DISTINCT ON (id)""lesson_modules"".*").joins(:academic_allocations).where(academic_allocations: {allocation_tag_id: params[:allocation_tags_ids]})
    @lesson = Lesson.find(params[:id])
    @groups = @lesson.lesson_module.groups
  end

  # PUT /lessons/1
  # PUT /lessons/1.json
  def update
    authorize! :update, Lesson, on: params[:allocation_tags_ids].split(" ")

    @lesson_modules = LessonModule.select("DISTINCT ON (id)""lesson_modules"".*").joins(:academic_allocations).where(academic_allocations: {allocation_tag_id: params[:allocation_tags_ids]})
    @lesson = Lesson.find(params[:id])
    error = false
    begin
      Lesson.transaction do
        @lesson.update_attributes!(params[:lesson])
        @lesson.schedule.update_attributes!(start_date: params[:start_date], end_date: params[:end_date])
      end
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue 
      @groups = @lesson.lesson_module.groups
      error = true
      @schedule_error = @lesson.schedule.errors.full_messages[0] unless @lesson.schedule.valid?
    end

    render (error ? {action: :edit} : {json: {success: true, notice: t(:updated, scope: [:lessons, :success])}})
  end

  # PUT /lessons/1/change_status/1
  def change_status
    authorize! :update, Lesson, on: params[:allocation_tags_ids].split(" ")

    ids = params[:id].split(',').map(&:to_i)

    msg = nil
    Lesson.where(id: [ids].flatten).find_each do |lesson|
      lesson.status = params[:status].to_i
      msg = lesson.errors.full_messages unless lesson.save
    end

    render json: {success: msg.nil?, msg: msg}, status: (msg.nil? ? :ok : :unprocessable_entity)
  end

  def destroy
    authorize! :destroy, Lesson, on: params[:allocation_tags_ids].split(" ")

    test_lesson = false
    Lesson.transaction do
      begin
        Lesson.where(id: params[:id].split(",")).each do |lesson|
          unless lesson.destroy
            lesson.status = Lesson_Test # a aula nao foi deletada, mas vai ser transformada em rascunho
            test_lesson = true
            raise "error" unless lesson.save
          end
        end
        render json: {success: true, notice: (test_lesson ? t(:saved_as_draft, scope: [:lessons, :success]) : t(:deleted, scope: [:lessons, :success]))}
      rescue
        render json: {success: false, alert: t(:deleted, scope: [:lessons, :errors])}, status: :unprocessable_entity
      end
    end
  end

  def show_header
    @lessons = lessons_to_open
    # render layout: 'lesson'
  end

  def download_files
    authorize! :download_files, Lesson, :on => params[:allocation_tags_ids]

    if verify_lessons_to_download(params[:lessons_ids].split(',').flatten, true)
      zip_file_path = compress(:under_path => @all_files_paths, :folders_names => @lessons_names)
      redirect      = request.referer.nil? ? home_url(:only_path => false) : request.referer

      if(zip_file_path)
        zip_file_name = zip_file_path.split("/").last
        download_file(redirect, zip_file_path, zip_file_name)
      else
        redirect_to redirect, alert: t(:file_error_nonexistent_file)
      end
      
    else
      render nothing: true
    end
  end

  # este método serve apenas para retornar um erro ou prosseguir com o download através da chamada ajax da página
  def verify_download
    begin
      authorize! :download_files, Lesson, :on => params[:allocation_tags_ids]
      raise "error" unless verify_lessons_to_download(params[:lessons_ids])
      status = 200
    rescue CanCan::AccessDenied
      status = :unauthorized
    rescue
      status = 500
    end
    render nothing: true, status: status 
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

  ##
  def change_module
    begin
      authorize! :change_module, Lesson, on: [params[:allocation_tags_ids]].flatten
      
      raise "#{t(:must_select_lessons, scope: [:lessons, :notifications])}" if params[:lessons_ids].empty?
      raise "#{t(:must_select_module, scope: [:lessons, :errors])}" if (params[:move_to_module].nil? || LessonModule.find(params[:move_to_module]).nil?)

      Lesson.transaction do
        Lesson.where(id: params[:lessons_ids].split(",")).update_all(lesson_module_id: params[:move_to_module])
      end

      render json: {success: true, msg: t(:moved, scope: [:lessons, :success])}
    rescue Exception => error
      render json: {success: false, msg: error.message}, status: :unprocessable_entity
    end
  end

  private

    def curriculum_data
      @curriculum_unit = CurriculumUnit.where(id: (params[:curriculum_unit_id] || active_tab[:url][:id])).first
    end

    def lessons_to_open(allocation_tags_ids = nil)
      allocation_tags_ids = allocation_tags_ids || AllocationTag.find(active_tab[:url][:allocation_tag_id]).related
      Lesson.to_open(allocation_tags_ids, current_user.id)
    end

    # define as variáveis e retorna se as aulas são válidas ou não para download
    def verify_lessons_to_download(lessons_ids, download_method = false)
      return false if lessons_ids.empty? # não selecionou nenhuma aula
      @lessons, @all_files_paths, @lessons_names = [], [], []

      lessons_ids.split(",").flatten.each do |lesson_id|
        lesson_dir   = File.join(Lesson::FILES_PATH, lesson_id)
        lesson_empty = ((not File.exist?(lesson_dir)) or (Dir.entries(lesson_dir).size <= 2))
        file_type    = Lesson.find(lesson_id.to_i).type_lesson == Lesson_Type_File

        if file_type and (not lesson_empty) # recupera apenas as aulas de arquivo que não estiverem vazias
          @lessons         << lesson_id.to_i # usado para verificação de erro
          @lessons_names   << Lesson.find(lesson_id.to_i).name  # usado para construção do zip
          @all_files_paths << File.join(Lesson::FILES_PATH, lesson_id) if download_method # recupera apenas se for no método de download / usado na recuperação dos arquivos
        end

      end

      return false if @lessons.empty?  # se nenhuma aula for do tipo arquivo ou se nenhuma aula possuir arquivos
      return true # se nenhum dos erros acontecer, está tudo ok
    end

end
