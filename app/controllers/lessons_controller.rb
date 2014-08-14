class LessonsController < ApplicationController

  include SysLog::Actions

  layout false, except: [:index]

  require 'fileutils'

  include FilesHelper
  include LessonFileHelper
  include LessonsHelper

  before_filter :prepare_for_group_selection, only: [:index, :download_files]
  before_filter :offer_data, only: [:show, :get_lessons]

  def index
    @not_offer_area = active_tab[:url][:allocation_tag_id].nil?  # if user is not at offer area
    if @not_offer_area
      allocation_tags = AllocationTag.get_by_params(params)
      @selected, @allocation_tags_ids = allocation_tags[:selected], allocation_tags[:allocation_tags]
      authorize! :index, Lesson, {on: @allocation_tags_ids, accepts_general_profile: true, read: true}
      @offer = Offer.find(allocation_tags[:offer_id])
    else 
      authorize! :index, Lesson, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]
      allocation_tag = AllocationTag.find(allocation_tag_id)
      @responsible   = allocation_tag.is_responsible?(current_user.id)
      @allocation_tags_ids = params.include?(:allocation_tags_ids) ? params[:allocation_tags_ids] : allocation_tag.related
    end

    @lessons_modules = LessonModule.to_select(@allocation_tags_ids.split(" ").flatten, current_user, true)
    render layout: false if params[:allocation_tags_ids] or @not_offer_area

    @allocation_tags_ids = @allocation_tags_ids.join(" ")
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def list
    @allocation_tags_ids = ( params.include?(:groups_by_offer_id) ? Offer.find(params[:groups_by_offer_id]).groups.map(&:allocation_tag).map(&:id) : params[:allocation_tags_ids])

    authorize! :list, Lesson, on: @allocation_tags_ids
    @academic_allocations = AcademicAllocation.select("DISTINCT on (academic_tool_id) *").where(academic_tool_type: 'LessonModule').where(allocation_tag_id: @allocation_tags_ids.split(" ").flatten).order("academic_tool_id").paginate(page: params[:page], per_page: 30)

    respond_to do |format|
      format.html
      format.js
    end
  rescue
    render nothing: true, status: 500
  end

  # GET /lessons/:id
  def show
    @lesson = Lesson.find(params[:id])
    raise "erro" if @lesson.address.blank?

    unless @offer or params.include?(:edition)
      render text: t(:curriculum_unit_not_selected, scope: :lessons), status: :not_found
    else
      authorize! :show, Lesson, {on: (@offer.nil? ? params[:allocation_tags_ids] : [@offer.allocation_tag.id]), read: true, accepts_general_profile: true}

      allocation_tags_ids = params.include?(:allocation_tags_ids) ? params[:allocation_tags_ids].split(" ").flatten : AllocationTag.find(active_tab[:url][:allocation_tag_id]).related
      @lessons_modules    = LessonModule.to_select(allocation_tags_ids, current_user)
      @lessons      = @lesson.lesson_module.lessons_to_open(current_user)
      @lessons_info = @lessons.collect{|lesson| {'id' => lesson.id, 'path' => lesson.path, 'url' => lesson_url(lesson), 'name' => lesson.name, 'is_draft' => (lesson.status == Lesson_Test)} }.to_json
      @student      = AllocationTag.find(active_tab[:url][:allocation_tag_id]).is_student?(current_user.id) unless active_tab[:url][:allocation_tag_id].nil?

      render layout: 'lesson'
    end
  rescue => error
    render json: {status: :unprocessable_entity}
  end

  def get_lessons
    lesson_module = LessonModule.find(params[:lesson_module])
    @lessons      = (lesson_module.nil? ? [] : lesson_module.lessons_to_open(current_user))
    @lessons_info = @lessons.collect{|lesson| {'id' => lesson.id, 'path' => lesson.path, 'url' => lesson_url(lesson), 'name' => lesson.name, 'is_draft' => (lesson.status == Lesson_Test)} }.to_json
    @student      = AllocationTag.find(active_tab[:url][:allocation_tag_id]).is_student?(current_user.id) unless active_tab[:url][:allocation_tag_id].nil?

    render partial: 'select_lesson', locals: { lessons: @lessons, lessons_info: @lessons_info }
  end

  # GET /lessons/new
  # GET /lessons/new.json
  def new
    authorize! :new, Lesson, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @lesson_module = LessonModule.find(params[:lesson_module_id]) if params[:lesson_module_id].present?
    @groups_codes  = @lesson_module.groups.map(&:code)
    @lesson = Lesson.new
  end

  # POST /lessons
  # POST /lessons.json
  def create
    authorize! :create, Lesson, on: @allocation_tags_ids = params[:allocation_tags_ids]

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
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue => error 
    @groups_codes    = @lesson_module.groups.map(&:code)
    params[:success] = false
    render :new
  end

  # GET /lessons/1/edit
  def edit
    authorize! :update, Lesson, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @lesson_modules = LessonModule.select("DISTINCT ON (id)""lesson_modules"".*").joins(:academic_allocations).where(academic_allocations: {allocation_tag_id: @allocation_tags_ids.split(" ").flatten})
    @lesson         = Lesson.find(params[:id])
    @groups_codes   = @lesson.lesson_module.groups.map(&:code)
  end

  # PUT /lessons/1
  # PUT /lessons/1.json
  def update
    authorize! :update, Lesson, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @lesson_modules = LessonModule.select("DISTINCT ON (id)""lesson_modules"".*").joins(:academic_allocations).where(academic_allocations: {allocation_tag_id: @allocation_tags_ids.split(" ").flatten})
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
      @groups_codes = @lesson.lesson_module.groups.map(&:code)
      error = true
      @schedule_error = @lesson.schedule.errors.full_messages[0] unless @lesson.schedule.valid?
    end

    if error
      params[:success] = false
      render :edit
    else
      render json: {success: true, notice: t(:updated, scope: [:lessons, :success])}
    end
  end

  # PUT /lessons/1/change_status/1
  def change_status
    authorize! :change_status, Lesson, {on: @allocation_tags_ids = params[:allocation_tags_ids], read: params.include?(:responsible)}
    @responsible = params.include?(:responsible)

    ids = params[:id].split(',').map(&:to_i).flatten
    msg = nil
    @lessons = Lesson.where(id: ids)
    @lessons.each do |lesson|
      lesson.status = params[:status].to_i
      msg = lesson.errors.full_messages unless lesson.save
    end
 
    respond_to do |format|
      if msg.nil?
        format.json { render json: {success: true}, status: :ok }
        format.js
      else
        format.json { render json: {success: false, msg: msg}, status: :unprocessable_entity }
        format.js { render js: "flash_message('#{msg.first}', 'alert');" }
      end
    end
  end

  def destroy
    authorize! :destroy, Lesson, on: params[:allocation_tags_ids]

    test_lesson = false
    @lessons = Lesson.where(id: params[:id].split(","))
    Lesson.transaction do
      begin
        @lessons.each do |lesson|
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

  def download_files
    authorize! :download_files, Lesson, on: params[:allocation_tags_ids]

    if verify_lessons_to_download(params[:lessons_ids].split(',').flatten, true)
      zip_file_path = compress(under_path: @all_files_paths, folders_names: @lessons_names)
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
      authorize! :download_files, Lesson, on: params[:allocation_tags_ids]
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

      l1, l2 = Lesson.where("id IN (?)", [params[:id], params[:change_id]])
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
      authorize! :change_module, Lesson, on: params[:allocation_tags_ids]
      
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

    def offer_data
      @offer = Offer.find(params[:offer_id] || active_tab[:url][:id])
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
