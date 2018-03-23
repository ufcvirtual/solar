class OffersController < ApplicationController

  include SysLog::Actions
  include ApplicationHelper
  include OffersHelper

  layout false

  # GET /semester/:id/offers
  def index
    authorize! :index, Semester # as ofertas aparecem na listagem de semestre
    @type_id  = params[:type_id].to_i
    @semester = Semester.find(params[:semester_id])
    @allocation_tags_ids = current_user.allocation_tags_ids_with_access_on([:update, :destroy], 'offers').join(' ')
    @offers   = @semester.offers_by_allocation_tags(@allocation_tags_ids.split(' '),
      { course_id: params[:course_id], curriculum_unit_id: params[:curriculum_unit_id] }).where("curriculum_units.curriculum_unit_type_id = :type_id OR curriculum_units.id IS NULL", {type_id: @type_id})
      .paginate(page: params[:page])

    respond_to do |format|
      format.html {render partial: 'offers/list'}
      format.js
    end
  end

  def new
    authorize! :new, Offer
    @type_id = params[:type_id].to_i

    params[:format] = :html
    @offer = Semester.find(params[:semester_id]).offers.build course_id: params[:course_id], curriculum_unit_id: params[:curriculum_unit_id]

    @offer.build_period_schedule
    @offer.build_enrollment_schedule
  end

  def edit
    @offer = Offer.find(params[:id])
    authorize! :edit, Offer, on: [@offer.allocation_tag.id]
    @type_id = params[:type_id].to_i

    #@offer.course.build

    @offer.build_period_schedule if @offer.period_schedule.nil?
    @offer.build_enrollment_schedule if @offer.enrollment_schedule.nil?
  end

  def create
    @type_id =  params[:offer][:type_id].to_i
    @offer   = Offer.new offer_params
    @offer.user_id = current_user.id
    @offer.type_id = @type_id

    optional_authorize(:create)

    if @offer.save
      render json: {success: true, notice: t(:created, scope: [:offers, :success])}
    else
      render :new
    end
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'offers.error')
  end

  def update
    @type_id =  params[:offer][:type_id].to_i
    @offer   = Offer.find(params[:id])
    
    optional_authorize(:update)
    update_offer_activities(@offer)
    
    if @offer.update_attributes(offer_params)
      render json: { success: true, notice: t(:updated, scope: [:offers, :success]) }
    else
      @offer.build_period_schedule     if @offer.period_schedule.nil?
      @offer.build_enrollment_schedule if @offer.enrollment_schedule.nil?

      render :edit
    end
  rescue => error
    render_json_error(error, 'offers.error')
  end

  def destroy
    @offers = Offer.where(id: params[:id].split(",").flatten)
    authorize! :destroy, Offer, on: @offers.map(&:allocation_tag).map(&:id)

    @offers.map(&:can_destroy?)
    @offers.destroy_all
   
    render json: {success: true, notice: t('offers.success.deleted')}
  rescue ActiveRecord::DeleteRestrictionError
    render json: {success: false, alert: t('offers.error.deleted')}, status: :unprocessable_entity
  rescue => error
    render_json_error(error, 'offers.error', 'deleted')
  end

  def deactivate_groups
    offer = Offer.find(params[:id])
    authorize! :deactivate_groups, Offer, on: [offer.allocation_tag.id]

    begin
      offer.groups.map { |group| group.update_attributes!(status: false) }

      flash[:notice] = t(:all_groups_deactivated, scope: [:offers, :index])
      render json: {success: true}
    rescue => error
      flash[:alert] = t(:cant_deactivate, scope: [:offers, :index])
      render json: {success: false}, status: :unprocessable_entity
    end
  end

  private

    def offer_params
      params.require(:offer).permit(:semester_id, :curriculum_unit_id, :course_id, enrollment_schedule_attributes: [:id, :start_date, :end_date, :_destroy], period_schedule_attributes: [:id, :start_date, :end_date, :_destroy])
    end

    def optional_authorize(method)
      at_c, at_uc = nil
      at_c  = AllocationTag.find_by_course_id(params[:offer][:course_id]).try(:id) unless params[:offer][:course_id].blank?
      at_uc = if params[:offer][:curriculum_unit_id].blank? 
        AllocationTag.joins(:curriculum_unit).joins("JOIN courses ON courses.name = curriculum_units.name AND courses.id = #{params[:offer][:course_id]}").first.try(:id) unless params[:offer][:course_id].blank? || params[:offer][:type_id].blank? || params[:offer][:type_id].to_i != 3
      else
        AllocationTag.find_by_curriculum_unit_id(params[:offer][:curriculum_unit_id]).try(:id) 
      end

      if at_c.nil? && at_uc.nil?
        authorize! method, Offer
      else
        begin
          authorize! method, Offer, on: [at_c]
        rescue
          authorize! method, Offer, on: [at_uc]
        end
      end
    end

    def update_offer_activities(offer)
      
      off_schedule = offer.offer_schedule_id.nil? ? nil : Schedule.find(offer.offer_schedule_id)
    
      #off_start_date = off_schedule.nil? ? offer.semester.offer_schedule.start_date : off_schedule.start_date
      #off_end_date = off_schedule.nil? ? offer.semester.offer_schedule.end_date : off_schedule.end_date
      
      param_off_start_date = params[:offer][:period_schedule_attributes][:start_date].blank? ? nil : Date.parse(params[:offer][:period_schedule_attributes][:start_date])
      param_off_end_date = params[:offer][:period_schedule_attributes][:end_date].blank? ? nil : Date.parse(params[:offer][:period_schedule_attributes][:end_date])
      
      if (param_off_end_date != nil && param_off_start_date != nil)
        
        group_id = Group.where(offer_id: offer.id).pluck(:id)
        allocation_tag_id = AllocationTag.where(group_id: group_id).pluck(:id)
        academic_allocation = AcademicAllocation.where(allocation_tag_id: allocation_tag_id)
        related_users_emails = Allocation.where(allocation_tag_id: allocation_tag_id).map{|al| al.user.email}
        activities_to_email = {}
        activities_to_save = []
        Struct.new('Activity_Object',:name, :start_date, :end_date)


        academic_allocation.each do |al|
          act = al.academic_tool

          if ['Assignment', 'Discussion', 'ChatRoom', 'Notification', 'ScheduleEvent'].include? al.academic_tool_type

            # se tentou mover o periodo total da oferta para antes do inicio ou depois do final da atividade
            if (param_off_start_date < act.schedule.start_date && param_off_end_date < act.schedule.start_date) || (param_off_start_date > act.schedule.end_date && param_off_end_date > act.schedule.end_date )
              raise "A atividade #{al.academic_tool_type} - #{act.name} não pode ser alterada para este período de oferta!"
            end

            if act.schedule.start_date < param_off_start_date
              act.schedule.start_date = param_off_start_date
            end

            if act.schedule.end_date > param_off_end_date
              act.schedule.end_date = param_off_end_date
            end

            if act.schedule.changed?
                struct = Struct::Activity_Object.new(act.name, act.schedule.start_date.to_s, act.schedule.end_date.to_s)
                activities_to_email[Object.const_get(al.academic_tool_type).model_name.human] ||= []
                activities_to_email[Object.const_get(al.academic_tool_type).model_name.human] << struct
                activities_to_save << act
            end

          end
          
          if ['Webconference'].include? al.academic_tool_type
            
            if act.initial_time < param_off_start_date
              act.initial_time = Time.new(param_off_start_date.year, param_off_start_date.month, param_off_start_date.day, act.initial_time.hour, act.initial_time.min, act.initial_time.sec)
            end

            if act.initial_time > param_off_end_date
              act.initial_time = Time.new(param_off_end_date.year, param_off_end_date.month, param_off_end_date.day, act.initial_time.hour, act.initial_time.min, act.initial_time.sec)
            end

            if act.changed?
              struct = Struct::Activity_Object.new(act.title, act.initial_time.to_date.to_s, act.initial_time.to_date.to_s)
              activities_to_email[Object.const_get(al.academic_tool_type).model_name.human] ||= []
              activities_to_email[Object.const_get(al.academic_tool_type).model_name.human] << struct
              activities_to_save << act
            end

          end

          if ['LessonModule'].include? al.academic_tool_type
            lessons = Lesson.where(lesson_module_id: act.id)

            lessons.each do |lesson|

              # se tentou mover o periodo total da oferta para antes do inicio ou depois do final da atividade
              if (param_off_start_date < lesson.schedule.start_date && param_off_end_date < lesson.schedule.start_date) || (param_off_start_date > lesson.schedule.end_date && param_off_end_date > lesson.schedule.end_date )
                activities_to_save = []
                activities_to_email = {}
                raise "A atividade #{al.academic_tool_type} - #{act.name} não pode ser alterada para este período de oferta!"
              end

              if lesson.schedule.start_date < param_off_start_date
                lesson.schedule.start_date = param_off_start_date
              end
  
              if lesson.schedule.end_date != nil && lesson.schedule.end_date  > param_off_end_date
                lesson.schedule.end_date = param_off_end_date
              end

              if lesson.schedule.changed?
                struct = Struct::Activity_Object.new(lesson.name, lesson.schedule.start_date.to_s, lesson.schedule.end_date.to_s)
                activities_to_email[Object.const_get(al.academic_tool_type).model_name.human] ||= []
                activities_to_email[Object.const_get(al.academic_tool_type).model_name.human] << struct
                activities_to_save << lesson
              end

            end

          end

          if ['Exam'].include? al.academic_tool_type
            
            difference_in_days = (act.schedule.end_date - act.schedule.start_date).to_i

            # se tentou mover o periodo total da oferta para antes do inicio da atividade
            if (act.schedule.start_date < param_off_start_date && act.schedule.end_date < param_off_start_date) || (act.schedule.end_date > param_off_end_date && act.schedule.start_date > param_off_end_date)
              raise "A atividade #{al.academic_tool_type} - #{act.name} não pode ser alterada para este período de oferta!"
            end

            if (act.schedule.start_date < param_off_start_date && difference_in_days == 0 )
              act.schedule.start_date = param_off_start_date
              act.schedule.end_date = param_off_start_date
            elsif act.schedule.start_date < param_off_start_date
              act.schedule.start_date = param_off_start_date
            end

            if (act.schedule.end_date > param_off_end_date && difference_in_days == 0)
              act.schedule.end_date = param_off_end_date
              act.schedule.start_date = param_off_end_date
            elsif act.schedule.end_date > param_off_end_date
              act.schedule.end_date = param_off_end_date
            end

            if act.changed?
              activities_to_email[al.academic_tool_type] ||= []
              activities_to_email[al.academic_tool_type] << act
              activities_to_save << act
            end
           
          end
          
        end

        unless activities_to_save.blank?
          ActiveRecord::Base.transaction do
            activities_to_save.each do |activity|
              activity.save
            end
          end
        end
        
        unless activities_to_email.blank?
          Notifier.send_mail(related_users_emails, "Alteração de Atividades", email_template(activities_to_email), []).deliver
        end

      end
    
    end

    def msg_template(activities)
      html = ""
      activities.each do |key, value|
        value.each do |object|
          if key == "Webconference"
            html << "<p>Atividade: #{key} - #{object.name} foi alterada para #{object.start_date}</p>"
          else
            html << "<p>Atividade: #{key} - #{object.name} foi alterada para #{object.start_date} à #{object.end_date}</p>"
          end
        end
      end
      html
    end

    def email_template(activities)
      %{#{msg_template(activities)}}    
    end

end
