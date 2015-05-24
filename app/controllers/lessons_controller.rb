class LessonsController < ApplicationController

  require 'fileutils'

  include SysLog::Actions
  include FilesHelper
  include LessonFileHelper
  include LessonsHelper

  before_filter :prepare_for_group_selection, only: :download_files
  before_filter :offer_data, only: :open
  before_filter :set_current_user, only: :update

  before_filter only: [:new, :create, :edit, :update] do |controller|
    authorize! crud_action, Lesson, { on: @allocation_tags_ids = params[:allocation_tags_ids] }
  end

  after_filter only: :update do 
    log(@lesson, "lesson: #{@lesson.id}, [copy original data] receive_updates_lessons: #{@lesson.receive_updates_lessons.pluck(:id)}") rescue nil
  end

  layout false, except: :index

  def index
    if (@not_offer_area = active_tab[:url][:allocation_tag_id].nil?) # if user is not at offer area / admin access
      index_admin_permissions
    else
      prepare_for_group_selection
      index_interacting_permissions
    end

    @lessons_modules = LessonModule.to_select(@allocation_tags_ids.split(' ').flatten, current_user, true)
    @allocation_tags_ids = @allocation_tags_ids.join(' ') if @allocation_tags_ids.is_a?(Array)

    render layout: false if @not_offer_area
  end

  def list
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :list, Lesson, { on: @allocation_tags_ids }

    @all_groups = Group.where(offer_id: params[:offer_id])
    @academic_allocations = LessonModule.academic_allocations_by_ats(@allocation_tags_ids.split(' '), page: params[:page])
  rescue
    render nothing: true, status: 500
  end

  # GET /lessons/:id
  def open
    authorize! :show, Lesson, { on: [@offer.allocation_tag.id], read: true, accepts_general_profile: true }

    at_ids = (params[:allocation_tags_ids].present? ? params[:allocation_tags_ids].split(' ') : AllocationTag.find(active_tab[:url][:allocation_tag_id]).related)

    @modules = LessonModule.to_select(at_ids, current_user)
    @lesson = Lesson.find(params[:id])

    render layout: 'lesson'
  rescue
    render text: t('lessons.no_data'), status: :unprocessable_entity
  end

  def to_filter
    authorize! :show, Lesson

    @module = LessonModule.find(params[:lesson_module_id])
    render partial: 'lessons/open/lessons', locals: { lesson_module: @module }
  end

  # GET /lessons/new
  # GET /lessons/new.json
  def new
    @lesson = Lesson.new lesson_module_id: params[:lesson_module_id]
    @lesson.build_schedule start_date: Date.today

    groups_by_lesson(@lesson)
  end

  # POST /lessons
  # POST /lessons.json
  def create
    @lesson = Lesson.new lesson_params
    @lesson.user = current_user
    @lesson.save!

    if @lesson.is_file?
      files_and_folders(@lesson)
      render template: 'lesson_files/index'
    else
      render json: { success: true, notice: t('lessons.success.created') }
    end
  rescue ActiveRecord::RecordInvalid
    groups_by_lesson(@lesson)
    render :new
  rescue => error
    request.format = :json
    raise error.class
  end

  # GET /lessons/1/edit
  def edit
    verify_owner(params[:id])
    lesson_modules_by_ats(@allocation_tags_ids)
    groups_by_lesson(@lesson)
  end

  # PUT /lessons/1
  # PUT /lessons/1.json
 def update
    verify_owner(params[:id])
    @lesson.update_attributes! lesson_params

    render json: { success: true, notice: t('lessons.success.updated') }
  rescue ActiveRecord::RecordInvalid
    lesson_modules_by_ats(@allocation_tags_ids)
    groups_by_lesson(@lesson)
    render :edit
  rescue => error
    request.format = :json
    raise error.class
  end

  def show
    authorize! :show, Lesson, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @lesson = Lesson.find(params[:id])
  end

  # PUT /lessons/1/change_status/1
  def change_status
    @responsible = params.include?(:responsible)
    @allocation_tags_ids = params[:allocation_tags_ids]

    authorize! :change_status, Lesson, { on: @allocation_tags_ids, read: @responsible }

    lesson_ids = params[:id].split(',').flatten
    msg = change_lessons_status(lesson_ids, params[:status])

    respond_to do |format|
      if msg.empty?
        format.json { render json: {success: true} }
        format.js
      else
        format.json { render json: { success: false, msg: msg }, status: :unprocessable_entity }
        format.js { render js: "flash_message('#{msg.first}', 'alert');" }
      end
    end
  end

  def destroy
    verify_owner(ids = params[:id].split(','))
    authorize! :destroy, Lesson, on: params[:allocation_tags_ids]

    lessons       = Lesson.where(id: ids)
    draft_lessons = lessons.where(status: Lesson_Test)

    Lesson.transaction do
      imported_to = draft_lessons.map(&:receive_updates_lessons).flatten.map(&:id)
      log(draft_lessons.first.lesson_module, "lessons: #{imported_to}, [remove files and copy original before removal] original: #{ids}") rescue nil if imported_to.any?
      log(draft_lessons.first.lesson_module, "lessons: #{draft_lessons.pluck(:id)}, [removal]", LogAction::TYPE[:destroy]) rescue nil if draft_lessons.any?
      lessons.destroy_all
    end

    render json: { success: true, notice: (draft_lessons.empty? ? t('lessons.success.saved_as_draft') : t('lessons.success.deleted')) }
  rescue
    render json: { success: false, alert: t('lessons.errors.deleted') }, status: :unprocessable_entity
  end

  def download_files
    authorize! :download_files, Lesson, on: params[:allocation_tags_ids]

    if verify_lessons_to_download(params[:lessons_ids], true)
      zip_file_path = compress(under_path: @all_files_paths, folders_names: @lessons_names)

      if zip_file_path
        redirect = request.referer.nil? ? home_url(only_path: false) : request.referer
        download_file(redirect, zip_file_path, File.basename(zip_file_path))
      else
        redirect_to redirect, alert: t(:file_error_nonexistent_file)
      end
    else
      render nothing: true
    end
  end

  # este método serve apenas para retornar um erro ou prosseguir com o download através da chamada ajax da página
  def verify_download
    status = verify_lessons_to_download(params[:lessons_ids]) ? :ok : :not_found
    render nothing: true, status: status
  end

  ## PUT lessons/:id/order/:change_id
  def order
    l1, l2 = Lesson.where(id: ids = [params[:id], params[:change_id]])

    verify_owner(ids)
    authorize! :update, l1

    Lesson.transaction do
      l1.order, l2.order = l2.order, l1.order
      l1.save!
      l2.save!
    end

    render json: { success: true }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  end

  def change_module
    verify_owner(lesson_ids = params[:lessons_ids].split(',') rescue [])
    authorize! :change_module, Lesson, on: params[:allocation_tags_ids]

    verify_owner(lesson_ids)

    new_module_id = LessonModule.find(params[:move_to_module]).id rescue nil

    raise t('lessons.notifications.must_select_lessons') if lesson_ids.empty?
    raise t('lessons.errors.must_select_module') if new_module_id.nil?

    Lesson.where(id: lesson_ids).update_all(lesson_module_id: new_module_id)

    render json: { success: true, msg: t('lessons.success.moved') }
  rescue => error
    render json: { success: false, msg: error.message }, status: :unprocessable_entity
  end

  ## Import ##
  def import_steps
    @ats   = params[:allocation_tags_ids]
    @types = CurriculumUnitType.all
    @lesson_module_id = params[:lesson_module_id]
    render partial: 'lessons/import/steps'
  end

  def import_list
    allocation_tags = AllocationTag.get_by_params(params)
    @selected, @allocation_tags_ids = allocation_tags[:selected], allocation_tags[:allocation_tags]
    authorize! :import, Lesson, { on: @allocation_tags_ids }
    @lmodules = LessonModule.by_ats(@allocation_tags_ids.split(' ').flatten)
    render partial: 'lessons/import/list'
  end

  def import_details
    @lessons = Lesson.find(params[:ids].split(' ').flatten).uniq
    authorize! :import, Lesson, { on: @lessons.map(&:allocation_tags).flatten.map(&:id).flatten, any: true }

    render partial: 'lessons/import/lesson'
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue
    render json: { success: false, alert: t('lessons.errors.import_empty') }, status: :unprocessable_entity
  end

  def import
    ActiveRecord::Base.transaction do
      raise 'import_empty' if params[:lessons].split(';').empty?
      lessons_to_import = Lesson.where(id: ids = params[:lessons].split(';').map{ |hash| hash.split(',')[0] })

      verify_owner(ids)
      authorize! :import, Lesson, { on: lessons_to_import.map(&:allocation_tags).flatten.map(&:id).flatten, any: true }
      authorize! :import, Lesson, { on: params[:allocation_tags_ids].split(' ').flatten }
      
      params[:lessons].split(';').each do |lesson_hash|
        lesson_hash = lesson_hash.split(',')
        lesson      = Lesson.find(lesson_hash[0])
        raise 'private_lesson' unless lesson.can_import?(current_user.id)
        raise 'draft_lesson'   if lesson.is_draft?
        attributes  = lesson.attributes.except('id', 'schedule_id', 'user_id', 'order', 'lesson_module_id', 'imported_from_id', 'receive_updates')
        schedule    = Schedule.create start_date: lesson_hash[2], end_date: lesson_hash[3]
        raise 'import_schedule' unless schedule.valid?

        if params[:lesson_module_id].blank?
          modules = LessonModule.by_name_and_allocation_tags_ids(lesson.lesson_module.name, params[:allocation_tags_ids].split(' ').flatten)
          if modules.any?
            lesson_module_id = modules.first.id
          else
            lesson_module = LessonModule.new lesson.lesson_module.attributes.except('id')
            lesson_module.allocation_tag_ids_associations = params[:allocation_tags_ids].split(' ').flatten
            lesson_module.save!
            lesson_module_id = lesson_module.id
            created_module = true
          end
        else
          lesson_module_id = params[:lesson_module_id]
        end

        imported_lesson = Lesson.new attributes.merge!({ 'order' => lesson_hash[1].to_i, 'schedule_id' => schedule.id, 'lesson_module_id' => lesson_module_id, 'imported_from_id' => lesson.id, 'receive_updates' => lesson_hash[4], 'user_id' => current_user.id })
        imported_lesson.save!

        log(LessonModule.find(lesson_module_id), "lesson: #{imported_lesson.id} [import], #{attributes.merge!(created_module: created_module, start_date: lesson_hash[2], end_date: lesson_hash[3])}", LogAction::TYPE[:create]) rescue nil
      end
    end
    
    render json: { success: true, msg: t('lessons.success.imported') }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'lessons.errors')
  end

  def import_preview
    @lesson = Lesson.find(params[:id])
    authorize! :import, Lesson, { on: @lesson.allocation_tags.map(&:id).flatten, any: true }
    render partial: 'lessons/open/content'
  end

  private

    def change_lessons_status(lesson_ids, new_status)
      msg = []
      @lessons = Lesson.where(id: lesson_ids)
      @lessons.each do |lesson|
        lesson.status = new_status
        msg << lesson.errors[:base] unless lesson.save
      end
      msg
    end

    def index_interacting_permissions
      authorize! :index, Lesson, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]

      allocation_tag = AllocationTag.find(allocation_tag_id)
      @responsible   = allocation_tag.is_responsible?(current_user.id)
      @allocation_tags_ids = params[:allocation_tags_ids].present? ? params[:allocation_tags_ids] : allocation_tag.related
    end

    def index_admin_permissions
      allocation_tags = AllocationTag.get_by_params(params)
      @selected, @allocation_tags_ids = allocation_tags[:selected], allocation_tags[:allocation_tags]

      authorize! :index, Lesson, { on: @allocation_tags_ids, accepts_general_profile: true, read: true }
      @offer = Offer.find(allocation_tags[:offer_id])
    end

    def lesson_modules_by_ats(atgs)
      @lesson_modules = LessonModule.select('DISTINCT ON (lesson_modules.id) lesson_modules.*')
        .joins(:academic_allocations).where(academic_allocations: { allocation_tag_id: atgs.split(' ').flatten })
    end

    def groups_by_lesson(lesson)
      @groups = lesson.lesson_module.groups
    end

    def offer_data
      @offer = Offer.find(params[:offer_id] || active_tab[:url][:id])
    end

    def lessons_to_open(allocation_tags_ids = nil)
      allocation_tags_ids = allocation_tags_ids || AllocationTag.find(active_tab[:url][:allocation_tag_id]).related
      Lesson.to_open(allocation_tags_ids, current_user.id)
    end

    # define as variaveis e retorna se as aulas sao validas ou nao para download
    def verify_lessons_to_download(lessons_ids, download_method = false)
      return false if lessons_ids.empty? # nao selecionou nenhuma aula

      @lessons, @lessons_names, @all_files_paths = [], [], []

      lessons_files = Lesson.where(id: lessons_ids.split(',').flatten, type_lesson: Lesson_Type_File)
      lessons_files.each do |lesson|
        if lesson.valid_file?
          @lessons << lesson.id # usado para verificacao de erro
          if download_method # recupera apenas se for no método de download / usado na recuperacao dos arquivos
            @lessons_names << lesson.name
            @all_files_paths << lesson.path(full_path = true, with_address = false).to_s
          end
        end
      end

      return false if @lessons.empty? # se nenhuma aula for do tipo arquivo ou se nenhuma aula possuir arquivos
      return true
    end

    def lesson_params
      params.require(:lesson).permit(:name, :description, :type_lesson, :address, :lesson_module_id, :privacy, :receive_updates, schedule_attributes: [:id, :start_date, :end_date])
    end

    def verify_owner(ids)
      if ids.kind_of?(Array)
        @lessons = Lesson.where(id: ids)
        private_lessons = @lessons.where(privacy: true)
        raise CanCan::AccessDenied unless private_lessons.size == private_lessons.where(user_id: current_user.id).size
      else
        @lesson = Lesson.find(ids)
        raise CanCan::AccessDenied if @lesson.privacy && @lesson.user_id != current_user.id
      end
    end

    def params_to_log
      { user_id: current_user.id, ip: request.remote_ip }
    end

    def log(object, message, type=LogAction::TYPE[:update])
      object.academic_allocations.each do |ac|
        LogAction.create(params_to_log.merge!(description: message, academic_allocation_id: ac.id, log_type: type))
      end
    end

end
