class ExamsController < ApplicationController

  include SysLog::Actions

  before_filter :prepare_for_group_selection, only: :index
  before_filter :get_groups_by_allocation_tags, only: [:new, :create]
  before_filter :verify_exam, only: [:open]
  layout false, except: :index

  def index
    @allocation_tag_id = active_tab[:url][:allocation_tag_id]
    authorize! :index, Exam, on: [@allocation_tag_id]
    @allocation_tags_ids = AllocationTag.find(@allocation_tag_id).related
    @exams = Exam.my_exams(@allocation_tags_ids)
    @can_open = can? :open, Exam, {on: @allocation_tag_id}
  rescue
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  end

  def new
    @allocation_tags_ids = params[:allocation_tags_ids]
    @exam = Exam.new
    @exam.build_schedule(start_date: Date.today, end_date: Date.today)
  end

  def create
    authorize! :create, Exam, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @exam = Exam.new exam_params
    @exam.allocation_tag_ids_associations = @allocation_tags_ids.split(' ').flatten
    @exam.schedule.verify_today = true

    if @exam.save
      render_exam_success_json('created')
    else
      render :new
    end
  rescue => error
    render_json_error(error, 'exams.error')
  end

  # require 'will_paginate/array'
  def list
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    @selected = params[:selected]
    authorize! :list, Exam, { on: @allocation_tags_ids }

    @all_groups = Group.where(offer_id: params[:offer_id])
    @exams = Exam.exams_by_ats(@allocation_tags_ids.split(' '))#.paginate(page: params[:page], per_page: 1)
    @can_see_preview = can? :show, Question, { on: @allocation_tags_ids }
    respond_to do |format|
      format.html
      format.js
    end
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exams.error')
  end

  def edit
    @exam = Exam.find(params[:id])
  end

  def update
    @exam = Exam.find(params[:id])
    authorize! :update, Exam, { on: @exam.academic_allocations.pluck(:allocation_tag_id) }
    @exam.schedule.verify_today = true
    if @exam.update_attributes(exam_params)
      render_exam_success_json('updated')
    else
      render :edit
    end
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exams.error')
  end

  def destroy
    authorize! :destroy, Exam, { on: params[:allocation_tags_ids] }
    Exam.find(params[:id]).destroy
    render_exam_success_json('deleted')
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exams.error')
  end

  def pre
    authorize! :open, Exam, { on: @allocation_tag_id = active_tab[:url][:allocation_tag_id] }
    @exam = Exam.find(params[:id])
    @situation = params[:situation]

    acs = @exam.academic_allocations
    ac_id = (acs.size == 1 ? acs.first.id : acs.where(allocation_tag_id: @allocation_tag_id).first.id)

    @acu = AcademicAllocationUser.find_or_create_one(ac_id, @allocation_tag_id, current_user.id, nil, true)

    last_attempt = @acu.exam_user_attempts.last

    raise 'time' unless @exam.on_going?
    raise 'attempt' unless @acu.has_attempt(@exam)
    
    if (last_attempt.try(:uninterrupted_or_ended, @exam))
      redirect_to result_user_exam_path(@exam)
    else
      @total_attempts  = @acu.count_attempts rescue 0
      @total_time = (last_attempt.try(:complete) ? 0 : last_attempt.try(:get_total_time)) || 0
      @text = if !last_attempt.nil? && !last_attempt.try(:complete)
        t("exams.pre.continue")
      else
        t("exams.pre.button")
      end
      render :pre
    end
  rescue => error
    render text: (I18n.translate!("exams.error.#{error}", raise: true) rescue t("exams.error.general_message"))
  end

  def open
    @disabled = false

    @last_attempt = @acu.find_or_create_exam_user_attempt
    @exam_questions = ExamQuestion.list(@exam.id, @exam.raffle_order, @last_attempt).paginate(page: params[:page], per_page: 1, total_entries: @exam.number_questions) unless @exam.nil?
    @total_time = (@last_attempt.try(:complete) ? 0 : @last_attempt.try(:get_total_time)) || 0
    
    if (params[:situation] == 'finished' || params[:situation] == 'corrected')
      mod_correct_exam = @exam.attempts_correction
      @exam_user_attempt_id = params[:exam_user_attempt_id]
      @disabled = true

      @exam_questions = ExamQuestion.list_correction(@exam.id, @exam.raffle_order).paginate(page: params[:page], per_page: 1, total_entries: @exam.number_questions) unless @exam.nil?
      if(mod_correct_exam != 1)
        @exam_user_attempt_id = Exam.get_id_exam_user_attempt(mod_correct_exam, @acu.id)
      end  

      @list_eua = ExamUserAttempt.where(academic_allocation_user_id: @acu.id)
      if mod_correct_exam == 1 && !params[:exam_user_attempt_id]  && params[:pdf].to_i != 1  
        render :open_result 
      else  
        @last_attempt = @exam.responses_question_user(@acu.id, params[:exam_user_attempt_id]) 
        if params[:pdf].to_i == 1
          @grade_pdf = ExamUserAttempt.find(@exam_user_attempt_id).grade
          @ats = AllocationTag.find(@allocation_tag_id)
          @exam_questions = ExamQuestion.list_correction(@exam.id, @exam.raffle_order) unless @exam.nil?
          @pdf = 1
          render :result_exam
        else  
         render :open 
        end
      end 
    else  
      respond_to do |format|
        format.html
        format.js
      end
    end
  rescue CanCan::AccessDenied
    render text: t(:no_permission)
  rescue => error
    render text: error.to_s
  end

  def result_exam_user
    @user_id = current_user.id
    begin
      authorize! :open, Exam, { on: @allocation_tag_id = active_tab[:url][:allocation_tag_id] }
    rescue
      authorize! :calcule_grades, Exam, { on: @allocation_tag_id }
      @user_id = params[:user_id]
    end
    @exam = Exam.find(params[:id])
    raise 'dates' unless @exam.ended?

    acs = @exam.academic_allocations
    @ac = (acs.size == 1 ? acs.first : acs.where(allocation_tag_id: active_tab[:url][:allocation_tag_id]).first)
    @acu = AcademicAllocationUser.find_one(@ac.id, @user_id)
    @frequency = @ac.frequency && (can? :calcule_grades, Exam, { on: @allocation_tag_id })
    raise 'empty' if @acu.nil? && !@frequency

    @grade = ((@acu.try(:grade).blank? || @exam.can_correct?(@user_id, AllocationTag.find(@allocation_tag_id).related)) ? @exam.recalculate_grades(@user_id, nil, true) : @acu.grade)

    @attempts = @acu.try(:exam_user_attempts) || []
    @scores_exam = @exam.exam_questions.where(use_question: true).sum(:score)

  rescue CanCan::AccessDenied
    render text: t(:no_permission)
  rescue => error
    render text: (I18n.translate!("exams.error.#{error}", raise: true) rescue t("exams.error.general_message"))
  end

  def complete
    exam = Exam.find(params[:id])
    acs = exam.academic_allocations
    acu = AcademicAllocationUser.find_one((acs.size == 1 ? acs.first.id : acs.where(allocation_tag_id: active_tab[:url][:allocation_tag_id]).first.id), current_user.id, nil, true)
    if acu.finish_attempt
      user_session[:blocking_content] = false
      if (params[:error])
        respond_to do |format|
          format.js { render :js => "validation_error('#{I18n.t('exam_responses.error.' + params[:error] + '')}');" }
        end
      else
        render_exam_success_json('finish')
      end
    end
  rescue => error
    render_json_error(error, 'exams.error')
  end

  def calcule_grade_user
    exam = Exam.find(params[:id])
    user_id = current_user.id
    if params.include?(:user_id)
      authorize! :calcule_grades, Exam, { on: active_tab[:url][:allocation_tag_id] }
      user_id = params[:user_id]
    end
    grade = exam.recalculate_grades(user_id, nil, true)
    render json: { success: true, grade: grade, status: t('exams.situation.corrected'), notice: t('calcule_grade', scope: 'exams.list') }
  rescue => error
    render_json_error(error, 'exams.error')
  end 

  def calcule_grade
    allocation_tags_ids = params.include?(:allocation_tags_ids) ? params[:allocation_tags_ids] : active_tab[:url][:allocation_tag_id]
    authorize! :calcule_grades, Exam, { on: allocation_tags_ids }
    ats = allocation_tags_ids.gsub(' ', ",") rescue allocation_tags_ids

    exam = Exam.find(params[:id])
    exam.recalculate_grades(nil, ats, true)
    render json: { success: true, notice: t('calcule_grade', scope: 'exams.list') }
  rescue => error
    render_json_error(error, 'exams.error')
  end

  def calcule_all
    authorize! :calcule_grades, Exam, { on: active_tab[:url][:allocation_tag_id] }
    ats = AllocationTag.find(active_tab[:url][:allocation_tag_id]).related
    ats_string = ats.join(',')

    Exam.joins(:academic_allocations).where(status: true, academic_allocations: { allocation_tag_id: ats }).each do |exam|
      exam.recalculate_grades(nil, ats_string, true)
    end

    redirect_to scores_path#, notice: t('calcule_grade', scope: 'exams.list')
  rescue => error
    render_json_error(error, 'exams.error')
  end

  def change_status
    authorize! :change_status, Exam, { on: params[:allocation_tags_ids] }
    exam = Exam.find(params[:id])
    exam.can_change_status?
    exam.update_attributes status: !exam.status

    render_exam_success_json('status')
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exams.error')
  end

  def show
    authorize! :show, Exam, { on: params[:allocation_tags_ids] }
    @exam = Exam.find(params[:id])
  end

  def preview
    authorize! :show, Question, { on: params[:allocation_tags_ids] }
    @exam = Exam.find(params[:id])
    @preview = true
    @exam_questions = Question.where(id: ExamQuestion.list(@exam.id, @exam.raffle_order).map(&:question_id)).paginate(page: params[:page], per_page: 1, total_entries: @exam.number_questions) unless @exam.nil?

    render :open
  end

  private

  def exam_params
    params.require(:exam).permit(:name, :description, :duration, :start_hour, :end_hour, 
                                 :random_questions, :raffle_order, :auto_correction, 
                                 :block_content, :number_questions, :attempts, 
                                 :attempts_correction, :result_email, :uninterrupted,
                                 schedule_attributes: [:id, :start_date, :end_date])
  end

  def render_exam_success_json(method)
    render json: { success: true, notice: t(method, scope: 'exams.success') }
  end

  def verify_time
    if params[:situation] == 'finished' || params[:situation] == 'corrected'
      raise 'not_finished' unless @exam.ended?
    else
      raise 'time' unless @exam.on_going?
    end
  end

  def verify_exam
    @exam = Exam.find(params[:id])
    @allocation_tag_id = active_tab[:url][:allocation_tag_id]
    acs = @exam.academic_allocations
    ac_id = (acs.size == 1 ? acs.first.id : acs.where(allocation_tag_id: @allocation_tag_id).first.id)
    unless user_session[:exams].include?(params[:id])
      authorize! :open, Exam, { on: @allocation_tag_id }
      user_session[:blocking_content] = Exam.verify_blocking_content(current_user.id)
      verify_time 
      user_session[:exams] << params[:id]

      @acu = AcademicAllocationUser.find_or_create_one(ac_id, @allocation_tag_id, current_user.id, nil, true)
      raise 'attempts' unless @acu.has_attempt(@exam) || ['corrected', 'finished', 'not_corrected'].include?(@acu.status_exam)
    else
      @acu = AcademicAllocationUser.find_one(ac_id, current_user.id, nil, true)
    end
  end

end