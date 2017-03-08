include EdxHelper

class EditionsController < ApplicationController

  layout false, only: [:tool_management]

  def items
    if active_tab[:url][:allocation_tag_id].blank?
      allocation_tags = AllocationTag.get_by_params(params)
      @allocation_tags_ids, @selected, @offer_id = allocation_tags.values_at(:allocation_tags, :selected, :offer_id)
    else
      @allocation_tags_ids, @selected, @offer_id = [active_tab[:url][:allocation_tag_id]], 'GROUP', params[:offer_id]
    end
    authorize! :content, Edition, on: @allocation_tags_ids
    @user_profiles       = current_user.resources_by_allocation_tags_ids(@allocation_tags_ids)
    @allocation_tags_ids = @allocation_tags_ids.join(" ")

    render partial: 'items'
  rescue=> error
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  # GET /editions/academic
  def academic
    authorize! :academic, Edition
    @types = ((!EDX.nil? && EDX["integrated"]) ? CurriculumUnitType.all : CurriculumUnitType.where("id <> 7"))
    @type  = params[:type_id]
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def courses
    authorize! :courses, Edition

    allocation_tags_ids = current_user.allocation_tags_ids_with_access_on([:update, :destroy], "courses")
    except_courses = (@type_id == 3 ? '' : Course.all_associated_with_curriculum_unit_by_name.pluck(:id).join(','))
    @search_courses = Course.joins(:allocation_tag).where(allocation_tags: {id: allocation_tags_ids}).where("courses.id NOT IN (#{except_courses})")
    @courses = @search_courses.paginate(page: params[:page])
    @type    = CurriculumUnitType.find(params[:curriculum_unit_type_id])
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def curriculum_units
    authorize! :curriculum_units, Edition

    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    allocation_tags_ids = current_user.allocation_tags_ids_with_access_on([:update, :destroy], "curriculum_units")
    @search_curriculum_units = @type.curriculum_units.joins(:allocation_tag).where(allocation_tags: {id: allocation_tags_ids})
    @curriculum_units   = @search_curriculum_units.paginate(page: params[:page])
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def semesters
    authorize! :semesters, Edition
    @periods  = [[t(:actives, scope: [:editions, :semesters]), "active"], [t(:all, scope: [:editions, :semesters]), "all"]]
    @periods += Schedule.joins(:semester_periods).map {|p| [p.start_date.year, p.end_date.year] }.flatten.uniq.sort! {|x,y| y <=> x} # desc

    @allocation_tags_ids = AllocationTag.where(id: current_user.allocation_tags_ids_with_access_on([:update, :destroy], "offers")).map{|at| at.related}.flatten.uniq
    @type = CurriculumUnitType.find(params[:curriculum_unit_type_id])

    @curriculum_units = @type.curriculum_units.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids})
    @courses   = ( @type.id == 3 ? Course.all_associated_with_curriculum_unit_by_name : @courses = Course.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}) )
    @semesters = Semester.all_by_period({period: params[:period], user_id: current_user.id, type_id: @type.id}) # semestres do período informado ou ativos

    @allocation_tags_ids = @allocation_tags_ids.join(" ")
  rescue => error
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def groups
    authorize! :groups, Edition
    @type    = CurriculumUnitType.find(params[:curriculum_unit_type_id])
    @courses = (@type.id == 3 ? Course.all_associated_with_curriculum_unit_by_name : Course.all)
    @curriculum_units = (@type.id == 3 ? [] : CurriculumUnit.where(curriculum_unit_type_id: @type))
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def edx_courses
    @type    = CurriculumUnitType.find(params[:curriculum_unit_type_id])

    verify_or_create_user_in_edx(current_user)

    url = URI.parse(EDX_URLS['verify_user'].gsub(':username', current_user.username)+'instructor/')
    res = Net::HTTP.start(url.host, url.port) { |http| http.request(Net::HTTP::Get.new(url.path)) }
    uri_courses = JSON.parse(res.body) #pega endereco dos cursos
    courses_created_by_current_user = '[]'
      unless uri_courses.empty?
        if uri_courses.class == Hash && uri_courses.has_key?('error_message')
          raise uri_courses['error_message']
        else
          courses_created_by_current_user = ''
          for uri_course in uri_courses do
            url = URI.parse(EDX_URLS['information_course'].gsub(':resource_uri', uri_course))
            res = Net::HTTP.start(url.host, url.port) { |http| http.request(Net::HTTP::Get.new(url.path)) }
            courses_created_by_current_user  << res.body.chop! << ", \"resource_uri\":  \"#{uri_course}\""<<"}, "
          end

          courses_created_by_current_user = courses_created_by_current_user.chop
          courses_created_by_current_user = '[' + courses_created_by_current_user.chop! + ']'
        end
      end
      @edx_courses = JSON.parse(courses_created_by_current_user)

    render layout: false if params.include?(:layout)
  rescue => error
    redirect_to :back, alert: t('edx.errors.cant_connect')
  end

  # GET /editions/content
  def content
    authorize! :content, Edition
    @types = ((!EDX.nil? && EDX['integrated']) ? CurriculumUnitType.all : CurriculumUnitType.where('id <> 7'))

    @allocation_tag_id = active_tab[:url][:allocation_tag_id]
    unless @allocation_tag_id.nil?
      allocation_tag      = AllocationTag.find(@allocation_tag_id)
      @group              = allocation_tag.group

      @allocation_tags_ids, @selected, @offer_id = [@allocation_tag_id], 'GROUP', @group.offer_id
      @user_profiles       = current_user.resources_by_allocation_tags_ids(@allocation_tags_ids)
      @allocation_tags_ids = @allocation_tags_ids.join(" ")
    end

  rescue => error
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  end

  def repositories
    authorize! :repositories, Edition
  rescue
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  end

  def tool_management
    @allocation_tags_ids = params[:allocation_tags_ids].split(' ')
    @tool_name = params[:tool_name]

    raise 'only_groups_and_offer' if AllocationTag.where(id: @allocation_tags_ids).where('group_id IS NOT NULL OR offer_id IS NOT NULL').count != @allocation_tags_ids.size

    authorize! :tool_management, Edition, { on: @allocation_tags_ids }

    @tools = EvaluativeTool.find_tools(@allocation_tags_ids)
    @tools = @tools.group_by { |t| t['academic_tool_type'] }

    @groups = Group.joins(:allocation_tag).where(allocation_tags: { id: @allocation_tags_ids })
    @working_hours = @groups.first.curriculum_unit.try(:working_hours)
  end

  def manage_tools
    params[:academic_allocations] = params[:academic_allocations].collect{|key,value| value}
    params[:academic_allocations] = params[:academic_allocations].delete_if{|a| a.nil? || a['acs'].blank?}
    allocation_tags_ids = params[:academic_allocations].collect{|data| data['allocation_tags_ids'].delete('[]').split(',')}.flatten.map(&:to_i).uniq

    allocation_tags = AllocationTag.where(id: allocation_tags_ids)

    authorize! :tool_management, Edition, { on: allocation_tags_ids }

    errors = []

    at = allocation_tags.where('group_id IS NOT NULL OR offer_id IS NOT NULL')

    errors << t('evaluative_tools.errors.only_groups_and_offer') if at.count != allocation_tags_ids.size

    errors << t('evaluative_tools.errors.offer_period') unless at.first.offers.first.is_active?

    raise 'error' unless errors.empty?

    working_hours_errors = []
    final_weight_errors = []
    acs_errors = []
    ats_errors = []

    max_working_hours = at.first.offers.first.try(:curriculum_unit).try(:working_hours)

    ActiveRecord::Base.transaction do
      params[:academic_allocations].each do |data|
        acs = AcademicAllocation.where(id: data['acs'].delete('[]').split(',')).each do |ac|

          attributes = {'evaluative' => false, 'weight' => 1, 'final_weight' => 100, 'equivalent_academic_allocation_id' => nil, 'final_exam' => false, 'frequency' => false, 'max_working_hours' => 0 }

          unless data['equivalent_academic_allocation_id'].blank?
            begin
              equivalent = AcademicAllocation.find(data['equivalent_academic_allocation_id'])
              if equivalent.allocation_tag_id != ac.allocation_tag_id
                find_equivalent = AcademicAllocation.where(academic_tool_type: equivalent.academic_tool_type, academic_tool_id: equivalent.academic_tool_id, allocation_tag_id: ac.allocation_tag_id).first.id
                data['equivalent_academic_allocation_id'] = find_equivalent
              end
            rescue => error
              group = ac.allocation_tag.group
              if group
                errors << {ac: ac, messages: [t('evaluative_tools.errors.equivalent_group', group: group.code)]}
              else
                errors << {ac: ac, messages: [t('evaluative_tools.errors.equivalent_offer')]}
              end
              acs_errors << ac.id
            end
          end

          attributes.merge!(data.slice('evaluative', 'weight', 'equivalent_academic_allocation_id', 'final_exam', 'frequency', 'max_working_hours', 'final_weight'))

          unless ac.update_attributes(attributes)
            errors << {ac: ac, messages: ac.errors.full_messages}
            acs_errors << ac.id
          end

        end
      end

      allocation_tags.each do |at|
        # getting errors to working_hours
        unless max_working_hours.nil?
          acs = AcademicAllocation.where(allocation_tag_id: at.related, frequency: true).where('final_exam = false AND equivalent_academic_allocation_id IS NULL').pluck(:max_working_hours)
          if acs.any?
            wh = acs.sum(:max_working_hours)
            if wh != max_working_hours
              working_hours_errors << {at: at, wh: wh} 
              ats_errors << at.id
            end
          end
        end

        # getting errors to final_weight
        acs = AcademicAllocation.where(allocation_tag_id: at.related, evaluative: true).where('final_exam = false').select('distinct final_weight').pluck(:final_weight)
        if acs.any?
          sum = acs.inject(:+) || 0
          if sum != 100
            final_weight_errors << {at: at, sum: sum}
            ats_errors << at.id
          end
        end

        # recalculating users final grades (if exists)
        at.recalculate_students_grades
      end

      errors = errors.delete_if {|x| x == true}
      raise 'error' unless errors.blank? && working_hours_errors.blank? && final_weight_errors.blank?
    end

    message = AcademicAllocationUser.any_evaluated?(allocation_tags_ids) ? t('evaluative_tools.warnings.changes') : t('evaluative_tools.success.manage')
    render json: { success: true, notice: message }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t('evaluative_tools.errors.permission')}, status: :unprocessable_entity
  rescue => error
    alert = []
    
    errors.each do |error|
      alert << "#{t(error[:ac].academic_tool_type.tableize.singularize.to_sym, scope: [:activerecord, :models])} #{error[:ac].tool_name}: #{error[:messages].join('; ')}"
    end
    
    working_hours_errors.each do |error|
      alert << ["#{error[:at].groups.map(&:code).join(', ')}", t('evaluative_tools.errors.working_hour_error', max: max_working_hours, wh: error[:wh])].join(': ')
    end

    final_weight_errors.each do |error|
      alert << ["#{error[:at].groups.map(&:code).join(', ')}", t('evaluative_tools.errors.final_weight_error', sum: error[:sum])].join(': ')
    end

    alert = alert.uniq.join('<br/>')
    alert = t('evaluative_tools.errors.general_message') if alert.blank?
    render json: { success: false, alert: alert, acs: acs_errors.uniq.map(&:to_s), ats: ats_errors.uniq.map(&:to_s) }, status: :unprocessable_entity
  end

end
