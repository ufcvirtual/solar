class AdministrationsController < ApplicationController

  include FilesHelper
  include SysLog::Devise
  include SysLog::Actions

  layout false, except: [:users, :indication_users, :indication_users_specific, :indication_users_global, :allocation_approval, :lessons, :logs, :import_users, :responsibles]

  def users
    authorize! :users, Administration

    @types = [ [t('.name'), 'name'], [t(".email"), 'email'], [t(".username"), 'username'], [t(".cpf"), 'cpf'] ]
  end

  def search_users
    authorize! :users, Administration

    @type_search, @text_search = params[:type_search], [URI.unescape(params[:user]).split(' ').compact.join('%'), '%'].join unless params[:user].blank?
    allocation_tags_ids = current_user.allocation_tags_ids_with_access_on(['users'], 'administrations', true, true)
    @users      = User.find_by_text_ignoring_characters(@text_search, @type_search, allocation_tags_ids).paginate(page: params[:page])
    @can_change = current_user.profiles_with_access_on('update_user', 'administrations').any?

    respond_to do |format|
      format.html
      format.js
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def show_user
    authorize! :update_user, Administration
    @user, @can_change = User.find(params[:id]), true

    respond_to do |format|
      format.html { render partial: 'user', locals: {user: @user} }
      format.json { render json: @user }
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def edit_user
    authorize! :update_user, Administration
    @user = User.find(params[:id])
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def update_user
    authorize! :update_user, Administration

    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      render json: {success: true}, status: :ok
    else
      render json: {success: false, alert: @user.errors.full_messages.uniq.compact}, status: :unprocessable_entity
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def reset_password_user
    authorize! :reset_password_user, Administration
    @user = User.find(params[:id])
    token = @user.send_reset_password_instructions

    render json: {success: true, notice: t('administrations.success.email_sent'), token: token}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue 
    render json: {success: false, alert: t('administrations.success.email_not_sent')}
  end

  ## ALLOCATIONS

  def allocations_user
    authorize! :allocations_user, Administration

    allocation_tags_ids = current_user.allocation_tags_ids_with_access_on(['allocations_user'], 'administrations', false, true) # if has nil, exists an allocation with allocation_tag_id nil
    query = allocation_tags_ids.include?(nil) ? '' : ['allocation_tag_id IN (?)', allocation_tags_ids]

    @allocations_user = User.find(params[:id]).allocations.joins(:profile).where('NOT cast(profiles.types & ? as boolean)', Profile_Type_Basic).where(query)
    @profiles = @allocations_user.map(&:profile).flatten.uniq
    @periods  = [ [t(:active), ''] ]
    @periods += Semester.all.map{|s| s.name}.flatten.uniq.sort! {|x,y| y <=> x}
    @can_change = !(current_user.profiles_with_access_on('update_allocation', 'administrations').empty?)
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def show_allocation
    authorize! :update_allocation, Administration
    @allocation = Allocation.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @allocation}
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def edit_allocation
    authorize! :update_allocation, Administration
    @allocation = Allocation.find(params[:id])
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  ## levar metodo para allocations

  def update_allocation
    authorize! :update_allocation, Administration
    @allocation = Allocation.find(params[:id])

    @allocation.change_to_new_status params[:status].to_i, current_user

    respond_to do |format|
      format.html { render action: :show_allocation, id: params[:id] }
      format.json { render json: {status: 'ok'} }
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  ## INDICATION USERS

  def indication_users
    authorize! :indication_users, Administration
  end

  def indication_users_specific
    authorize! :indication_users, Administration
    @types = CurriculumUnitType.all
  end

  def indication_users_global
    authorize! :indication_users, Administration, { global: true }
    @allocations = Allocation.joins(:profile).where(allocation_tag_id: nil).where('NOT cast(profiles.types & ? as boolean)', Profile_Type_Basic)
    @admin = true
  end

  ## ALLOCATION APPROVAL
  require 'will_paginate/array'
  def allocation_approval
    authorize! :allocation_approval, Administration
    @allocations = Allocation.pending

    if params.include?(:search)
      @text_search, @type_search = URI.unescape(params[:value]), params[:type]
      text = "%#{[@text_search.split(" ").compact.join("%"), "%"].join}" unless @text_search.blank?

      @allocations =  case @type_search
                      when 'name'
                        query = "lower(unaccent(users.name)) LIKE lower(unaccent(?))" unless @text_search.blank?
                        @allocations.joins(:user).where(query, text)
                      when 'profile'; @allocations.joins(:profile).where('lower(unaccent(profiles.name)) LIKE lower(unaccent(?))', text)
                      else
                        unless text.nil?
                          ats = case @type_search
                                when 'curriculum_unit_type'; CurriculumUnitType.where("lower(unaccent(description || ' ')) LIKE lower(unaccent(?))", text).map(&:allocation_tag).map{|a| a.related({lower: true, sibblings: false})}
                                when 'course'; Course.where("lower(unaccent(name || code || ' ')) LIKE lower(unaccent(?))", text).map(&:allocation_tag).map{|a| a.related({lower: true, sibblings: false})}
                                when 'curriculum_unit'; CurriculumUnit.where("lower(unaccent(name || code || ' ')) LIKE lower(unaccent(?))", text).map(&:allocation_tag).map{|a| a.related({lower: true, sibblings: false})}
                                when 'semester'; Semester.where("lower(unaccent(name || ' ')) LIKE lower(unaccent(?))", text).map(&:offers).flatten.uniq.map(&:allocation_tag).map{|a| a.related({lower: true})}
                                when 'group'; Group.where("lower(unaccent(code || ' ')) LIKE lower(unaccent(?))", text).map(&:allocation_tag).uniq
                                end
                        end

                        ats.nil? ? @allocations : @allocations.where(allocation_tag_id: ats.flatten.uniq)
                      end
    end

    # if user isn't an admin, remove unrelated allocations
    @allocations = Allocation.remove_unrelated_allocations(current_user, @allocations) unless current_user.admin?

    @allocations.compact!
    @allocations = @allocations.paginate(page: params[:page])
    @types = [ [t('administrations.allocation_approval.name'), 'name'], [t('administrations.allocation_approval.profile'), 'profile'],
      [t('administrations.allocation_approval.type'), 'curriculum_unit_type'], [t('administrations.allocation_approval.course'), 'course'],
      [t('administrations.allocation_approval.curriculum_unit'), 'curriculum_unit'], [t('administrations.allocation_approval.semester'), 'semester'],
      [t('administrations.allocation_approval.group'), 'group'] ]

    respond_to do |format|
      format.html { render layout: false if params.include?(:search) }
      format.json { render json: @allocations }
      format.js
    end
  end

  ## Lessons
  def lessons
    authorize! :lessons, Administration

    @types = CurriculumUnitType.all
  end

  ## LOGS

  def logs
    authorize! :logs, Administration

    @types = [ [t(:actions, scope: [:administrations, :logs]), 'actions'], [t(:accesses, scope: [:administrations, :logs]), 'access'],[t(:navigations, scope: [:administrations, :logs]), 'navigation'] ]
    @download_types = [ [ 'csv', 'csv'], ['xls', 'xls'] ]
  end

  def search_logs
    authorize! :logs, Administration

    @logs, query = [], []
    date = Date.parse(params[:date]) rescue nil
    date_end = Date.parse(params[:date_end]) rescue Date.parse(Time.now.to_s)
    unless params[:user].blank?
      text_search = [URI.unescape(params[:user]).split(' ').compact.join('%'), '%'].join
      user_ids    = User.where("lower(unaccent(name)) LIKE lower(unaccent(?)) OR lower(unaccent(cpf)) LIKE lower(unaccent(?))" , "%#{text_search}", "%#{text_search}").map(&:id).join(',')
      if (params[:type] == 'actions' || params[:type] == 'access')
        query << "(user_id IN (#{user_ids}))" unless user_ids.blank?   
      else
         query << "log_navigations.user_id IN (#{user_ids})" unless user_ids.blank?
      end  
    end

    allocation_tags_ids = current_user.allocation_tags_ids_with_access_on([:logs], 'administrations', false, true)
    query << "allocation_tags.id IN (#{allocation_tags_ids.join(',')})" unless allocation_tags_ids.include?(nil)

    if (params[:type] == 'actions' || params[:type] == 'access')
      log = params[:type] == 'actions' ? LogAction : LogAccess
      query << "date(created_at) = '#{date.to_s(:db)}'" unless date.nil?
      join_query = (allocation_tags_ids.include?(nil) ? '' : "LEFT JOIN allocation_tags ON allocation_tags.id = #{log.to_s.tableize}.allocation_tag_id")
      @logs = log.joins(join_query).where(query.join(' AND ')).order('created_at DESC').limit(100)
    else
    if(date_end && date) 
     query << "log_navigations.created_at::date >= '#{date.to_s(:db)}' AND log_navigations.created_at::date <= '#{date_end.to_s(:db)}'" 
    else
     query << "log_navigations.created_at::date <= '#{date_end.to_s(:db)}'"
    end 

    @logs = LogNavigation.where(query.join(' AND '))
    @logs =  @logs.joins('LEFT JOIN log_navigation_subs lognsub ON log_navigations.id = log_navigation_id')
      .joins('LEFT JOIN  assignments ON lognsub.assignment_id = assignments.id')
      .joins('LEFT JOIN chat_rooms ON lognsub.chat_room_id = chat_rooms.id')
      .joins('LEFT JOIN chat_rooms as chat_historico ON lognsub.hist_chat_room_id = chat_historico.id')
      .joins('LEFT JOIN group_assignments ON lognsub.group_assignment_id = group_assignments.id')
      .joins('LEFT JOIN lessons ON lognsub.lesson_id = lessons.id')
      .joins('LEFT JOIN discussions ON lognsub.discussion_id = discussions.id')
      .joins('LEFT JOIN exams ON exams.id = lognsub.exam_id')
      .joins('LEFT JOIN users as student ON lognsub.student_id = student.id')
      .joins('LEFT JOIN users as participant ON lognsub.user_id = participant.id')
      .joins('LEFT JOIN webconferences ON lognsub.webconference_id = webconferences.id')
      .joins('LEFT JOIN menus ON log_navigations.menu_id = menus.id')
      .joins('LEFT JOIN allocation_tags ON log_navigations.allocation_tag_id = allocation_tags.id')
      .joins('LEFT JOIN groups ON groups.id = allocation_tags.group_id')
      .joins('LEFT JOIN offers ON offers.id = groups.offer_id OR offers.id = allocation_tags.offer_id')
      .joins('LEFT JOIN semesters ON semesters.id = offers.semester_id')
      .joins('LEFT JOIN courses ON offers.course_id = courses.id')
      .joins('LEFT JOIN curriculum_units ON offers.curriculum_unit_id = curriculum_units.id')
      .joins('LEFT JOIN users ON log_navigations.user_id = users.id')
      .select("
        DISTINCT log_navigations.id, 
        lognsub.id as id_sub, 
        users.name as user, 
        courses.name as course, 
        courses.code as course_code, 
        curriculum_units.name as uc, 
        curriculum_units.code as uc_code, 
        semesters.name as semester, 
        groups.code as group, 
        menus.name AS menu, 
        to_char(log_navigations.created_at,'dd/mm/YYYY HH24:MI:SS') as created, 
        support_material_file, 
        discussions.name as discussion,
        CASE lessons.type_lesson
        WHEN 0 THEN COALESCE(lessons.name, lesson)
        WHEN 1 THEN COALESCE(lessons.address, lesson)    
        ELSE
          lesson
        END AS lesson,
        assignments.name as assignment, 
        exams.name as exam, 
        chat_rooms.title as chat_room, 
        chat_historico.title as chat_history, 
        student.name as student, 
        group_assignments.group_name as group_assignments, 
        webconferences.title as webconferences,
        webconference_record,
        digital_class_lesson,
        lesson_notes,
        public_area,
        public_file_name, 
        participant.name as participant, 
        to_char(lognsub.created_at,'dd/mm/YYYY HH24:MI:SS') as created_submenu
      ")
      .order("log_navigations.id DESC, lognsub.id DESC")
      .limit(10000)
      attributes_to_include = %w(user course course_code uc uc_code semester group menu created created_submenu support_material_file discussion lesson lesson_notes assignment student group_assignments chat_room chat_history exam webconferences webconference_record public_area public_file_name participant digital_class_lesson)

      respond_to do |format|
        format.html        
        format.csv { send_data @logs.to_csv(attributes_to_include) }
        format.xls { render :navigation }  
      end
   end  
  end

  ## IMPORT USERS

  # GET /import/users/filter
  def import_users
    authorize! :import_users, Administration

    @types = CurriculumUnitType.all
  end

  # GET /import/users/form
  def import_users_form
    @allocation_tags_ids = AllocationTag.where(group_id: params[:groups_id].split(' ')).map(&:id)
    authorize! :import_users, Administration, { on: @allocation_tags_ids, accepts_general_profile: true }

  rescue CanCan::AccessDenied
    render json: {msg: t(:no_permission), alert: t(:no_permission)}, status: :unauthorized
  end

  # POST /import/users/batch
  def import_users_batch
    allocation_tags_ids = params[:allocation_tags_ids].split(' ').compact.uniq.map(&:to_i)
    authorize! :import_users, Administration, { on: allocation_tags_ids, accepts_general_profile: true }

    raise t(:invalid_file, scope: [:administrations, :import_users]) if (file = params[:batch][:file]).nil?

    delimiter = [';', ','].include?(params[:batch][:delimiter]) ? params[:batch][:delimiter] : ';'
    result = User.import(file, delimiter)
    users = result[:imported]
    @log  = result[:log]
    @count_imported = result[:log][:success].count

    users.each do |user|
      allocation_tags_ids.each do |at|
        begin
          AllocationTag.find(at).group.allocate_user(user.id, Profile.student_profile)
          @log[:success] << t(:allocation_success, scope: [:administrations, :import_users, :log], cpf: user.cpf, allocation_tag: at)
        rescue => error
          @log[:error] << t(:allocation_error, scope: [:administrations, :import_users, :log], cpf: user.cpf)
        end
      end
    end

    @log_file = save_log_into_file(@log[:success] + @log[:error])
  rescue CanCan::AccessDenied
    render json: { msg: t(:no_permission), alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    error = t('administrations.import_users.other_extension') if error.to_s.include?('UTF-8')
    error = t('administrations.import_users.other_delimiter') if error.to_s.include?('quoting')
    render json: { success: false, alert: "#{error}" }, status: :unprocessable_entity
  end

  # GET /import/users/log
  def import_users_log
    authorize! :import_users, Administration

    media_path = YAML::load(File.open('config/global.yml'))[Rails.env.to_s]['import_users']['media_path']
    file_path = File.join(Rails.root.to_s, media_path, params[:file])

    download_file(home_path, file_path, 'import-log.txt')
  end

  def responsibles
    authorize! :responsibles, Administration

    @types = CurriculumUnitType.all
  end

  def responsibles_list
    allocation_tags_ids = AllocationTag.get_by_params(params, false, true)[:allocation_tags]
    authorize! :responsibles, Administration, {on: allocation_tags_ids, accepts_general_profile: true}

    @allocations = Allocation.responsibles(allocation_tags_ids)

  rescue CanCan::AccessDenied
    render json: {msg: t(:no_permission), alert: t(:no_permission)}, status: :unauthorized
  end
  
  private

    def user_params
      params.require(:data).permit(:name, :email, :username, :active)
    end

    def save_log_into_file(logs)
      filename   = "#{current_user.id}-log-#{I18n.l(Time.now, format: :log)}"
      media_path = YAML::load(File.open('config/global.yml'))[Rails.env.to_s]['import_users']['media_path']

      FileUtils.mkdir_p(dir = File.join(Rails.root.to_s, media_path))
      File.open(File.join(dir, filename), 'w') do |f|
        f.puts(logs)
      end
      filename
    end

end
