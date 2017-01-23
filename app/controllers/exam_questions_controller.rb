class ExamQuestionsController < ApplicationController

  include SysLog::Actions

  before_filter :set_current_user, only: [:order, :annul, :import, :export]

  layout false, except: :index

  def index
    authorize! :list, Exam, { on: @allocation_tags_ids = params[:allocation_tags_ids] }

    @can_see_preview = can? :show, Question, { on: @allocation_tags_ids }
    exam      = Exam.find(params[:exam_id])
    questions = exam.get_questions
    render partial: 'questions', locals: { questions: questions, exam: exam, hide_columns: false }
  end

  def new
    authorize! :create, Question, { on: @allocation_tags_ids = params[:allocation_tags_ids] }
    @exam_question = ExamQuestion.new exam_id: params[:exam_id]
    build_exam_question
  end

  def create
    @exam_question = ExamQuestion.new exam_question_params
    authorize! :create, Question, { on: at_ids = @exam_question.exam.allocation_tags.map(&:id) }
    @exam_question.question.user_id = current_user.id

    if @exam_question.save
      if @exam_question.exam.questions.size > 1
        render partial: 'question', locals: { question: @exam_question.question, exam_question: @exam_question, exam: @exam_question.exam, hide_columns: false, can_see_preview: true }
      else
        redirect_to exam_questions_path(exam_id: @exam_question.exam_id, allocation_tags_ids: at_ids)
      end
    else
      render json: { success: false, alert: @exam_question.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end

  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exam_questions.errors')
  end

  def edit
    @exam_question = ExamQuestion.find(params[:id])
    build_exam_question
  end

  def update
    authorize! :update, Question
    @exam_question = ExamQuestion.find params[:id]

    if @exam_question.update_attributes exam_question_params
      render partial: 'question', locals: { question: @exam_question.question, exam_question: @exam_question, exam: @exam_question.exam, hide_columns: false, can_see_preview: true }
    else
     @errors = []
      @exam_question.errors.each do |attribute, erro|
        @errors << t(attribute) + erro
      end  
      render json: { success: false, alert: @errors.join(', ')}, status: :unprocessable_entity
    end

  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'questions.error')
  end

  def remove_image_item
    authorize! :update, Question
    @exam_question = ExamQuestion.find params[:exam_question_id]

    @question_item = QuestionItem.find params[:id]
    @question_item.item_image_file_name = nil
    @question_item.item_image_content_type = nil
    @question_item.item_image_file_size = nil
    @question_item.item_image_updated_at = DateTime.now
    @question_item.img_alt = nil

    if @question_item.save
      render json: { success: true, notice: t('questions.form.items.info_remove_image') }
    else
      render json: { success: false, alert: @exam_question.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end

  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'questions.error')
  end 

  def remove_audio_item
    authorize! :update, Question
    @exam_question = ExamQuestion.find params[:exam_question_id]

    @question_item = QuestionItem.find params[:id]
    @question_item.item_audio_file_name = nil
    @question_item.item_audio_content_type = nil
    @question_item.item_audio_file_size = nil
    @question_item.item_audio_updated_at = DateTime.now

    if @question_item.save
      render json: { success: true, notice: t('questions.form.items.info_remove_audio') }
    else
      render json: { success: false, alert: @exam_question.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end

  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'questions.error')
  end 


  def publish
    authorize! :change_status, Question
    ids = params[:id].split(',') rescue [params[:id]]
    ActiveRecord::Base.transaction do
      ExamQuestion.where(id: ids).each do |exam_question|
        exam_question.question.can_change_status?
        exam_question.question.update_attributes status: true
      end
    end

    render json: { success: true, notice: t('questions.success.change_status') }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'questions.error')
  end

  def order
    eq1, eq2 = ExamQuestion.where(id: ids = [params[:id], params[:change_id]])

    [eq1, eq2].map(&:can_reorder?)
    authorize! :update, Question, { on: Exam.find(params[:exam_id]).allocation_tags.map(&:id)}

    ExamQuestion.transaction do
      eq1.order, eq2.order = eq2.order, eq1.order
      eq1.save!
      eq2.save!
    end

    render json: { success: true }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exam_questions.errors')
  end

  def annul
    exam_question = ExamQuestion.find(params[:id])
    authorize! :annul, Question, { on: exam_question.exam.allocation_tags.map(&:id) }
    exam_question.can_change_annulled?
    exam_question.update_attributes annulled: true 
   
    log(exam_question.exam, "question: #{exam_question.question_id} [annul] exam: #{exam_question.exam_id}, #{exam_question.log_description.merge!(exam: exam_question.exam.attributes)}", LogAction::TYPE[:update]) rescue nil
    
    render json: { success: true, notice: t('exam_questions.success.annulled') }
  rescue => error
    render_json_error(error, 'exam_questions.errors')
  end

  def destroy
    exam_questions = ExamQuestion.where(id: params[:id].split(','))
    authorize! :destroy, Question, { on: exam_questions.first.exam.allocation_tags.map(&:id) }
    ActiveRecord::Base.transaction do
      exam_questions.each do |exam_question|
        exam_question.destroy
      end
    end
    render json: { success: true, notice: t('exam_questions.success.deleted') }
  rescue => error
    render_json_error(error, 'exam_questions.errors')
  end

  ## Import ##
  def import_steps
    @ats     = params[:allocation_tags_ids]
    @types   = CurriculumUnitType.all
    @exam_id = params[:exam_id].to_i || 0
    render partial: 'exam_questions/import/steps'
  end

  def import_list
    allocation_tags = AllocationTag.get_by_params(params)
    @selected, @allocation_tags_ids = allocation_tags[:selected], allocation_tags[:allocation_tags]
    authorize! :import_export, Question, { on: @allocation_tags_ids }
    @exams = Exam.exams_by_ats(@allocation_tags_ids.split(' ').flatten)
    @can_see_preview = can? :show, Question
    render partial: 'exam_questions/import/list'
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exam_questions.errors')
  end

  def import_details
    authorize! :import_export, Question

    if params[:search_method].to_i == 1
      @questions = Question.joins(:exam_questions).where(exam_questions: { id: params[:ids].split(' ').flatten.compact }).select('questions.*, exam_questions.exam_id AS exam_id, exam_questions.score AS score').uniq 
    else
      @questions = Question.find(params[:ids].split(' ').flatten.compact).uniq 
      raise 'bank_without_exam' if params[:exam_id].to_i == 0
    end  
    @exam = Exam.find(params[:exam_id].to_i) rescue nil

    @can_see_preview = can? :show, Question

    render partial: 'exam_questions/import/question'
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exam_questions.errors')
  end

  def import
    created_exam = false
    ActiveRecord::Base.transaction do
      raise 'import_empty' if params[:questions].split(';').empty?

      authorize! :import_export, Question, { on: params[:allocation_tags_ids].split(' ').flatten }

      
      params[:questions].split(';').each do |question_hash|
        question_hash = question_hash.split(',')
        question      = Question.find(question_hash[0])
        question.can_import_or_export?(current_user)
         
        if params[:exam_id].blank? || params[:exam_id].to_i.zero?
          raise 'bank_without_exam' if question_hash[2].blank?
          exam  = Exam.find(question_hash[2])
          exams = Exam.by_name_and_allocation_tags_ids(exam.name, params[:allocation_tags_ids].split(' ').flatten)
          if exams.any?
            exam_id = exams.first.id
          else
            schedule = Schedule.create exam.schedule.attributes.except('id') 
            exam     = Exam.new exam.attributes.except('id', 'schedule_id', 'status').merge({ status: false, schedule_id: schedule.id })
            exam.allocation_tag_ids_associations = params[:allocation_tags_ids].split(' ').flatten
            exam.save!
            exam_id = exam.id
            created_exam = true
          end
        else
          exam_id = params[:exam_id]
          Exam.find(exam_id).can_import?(question)
        end

        exam_question = ExamQuestion.new({ 'question_id' => question.id, 'order' => question_hash[1].to_i, 'score' => question_hash[3].to_f, 'exam_id' => exam_id })
        exam_question.save!

        log(Exam.find(exam_id), "question: #{question.id} [import] exam: #{exam_id}, #{exam_question.log_description}", LogAction::TYPE[:create]) rescue nil
      end
    end

    if created_exam
      render json: { success: true, msg: t('exam_questions.success.imported_with_exam') }
    else
      render json: { success: true, msg: t('exam_questions.success.imported') }
    end
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exam_questions.errors', 'general_message', ("#{error}".split(' ').size == 1 ? nil : error))
  end

  def import_preview
    @question = Question.find(params[:id])
    @question.can_see?
    render partial: 'exam_questions/open/content'
  rescue => error
    render_json_error(error, 'exam_questions.errors')
  end

  ## Export ##
  def export_steps
    @types     = CurriculumUnitType.all
    @questions = params[:id]
    render partial: 'exam_questions/export/steps'
  rescue => error
    render_json_error(error, 'exam_questions.errors')
  end

  def export_list
    allocation_tags = AllocationTag.get_by_params(params)
    @selected, @allocation_tags_ids = allocation_tags[:selected], allocation_tags[:allocation_tags]
    authorize! :import_export, Question, { on: @allocation_tags_ids }
    @exams = Exam.exams_by_ats(@allocation_tags_ids.split(' ').flatten)
    render partial: 'exam_questions/export/list'
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exam_questions.errors')
  end

  def export_details
    authorize! :import_export, Question
    @exams = Exam.find(params[:ids].split(' '))
    @questions = Question.find(params[:questions_ids].split(','))
    render partial: 'exam_questions/export/exam'
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exam_questions.errors')
  end

  def export
    ActiveRecord::Base.transaction do
      raise 'export_empty' if params[:questions].split(';').empty?

      authorize! :import_export, Question

      params[:questions].split(';').each do |question_hash|
        question_hash = question_hash.split(',')
        question      = Question.find(question_hash[0])
        exam          = Exam.find(question_hash[1])
        question.can_import_or_export?(current_user, exam)
        exam.can_import?

        raise CanCan::AccessDenied unless can? :import_export, Question, { on: exam.allocation_tags.map(&:id) }
       
        exam_question = ExamQuestion.create!({ 'question_id' => question.id, 'score' => question_hash[2].to_i, 'exam_id' => exam.id })

        log(exam, "question: #{question.id} [export] exam: #{exam.id}, #{exam_question.log_description }", LogAction::TYPE[:create]) rescue nil
      end
    end
    
    render json: { success: true, msg: t('exam_questions.success.exported') }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exam_questions.errors', 'general_message', ("#{error}".split(' ').size == 1 ? nil : error))
  end

  def copy
    authorize! :copy, Question
    exam_question  = ExamQuestion.find params[:id]
    exam_question.can_save?
    exam_question.question.can_copy?
    @exam_question = ExamQuestion.copy(exam_question, current_user.id)

    log(ExamQuestion.exam, "question: #{exam_question.question_id} [copy], #{exam_question.log_description}", LogAction::TYPE[:create]) rescue nil

    build_exam_question

    render :edit
  rescue CanCan::AccessDenied
    render text: t(:no_permission)
  rescue => error
    render text: t("exam_questions.errors.#{error}")
    # render_json_error(error, 'exam_questions.errors')
  end

  private

  def exam_question_params
    params.require(:exam_question).permit(
      :exam_id, :score, :order,
      question_attributes: [
        :id, :name, :enunciation, :type_question, 
        question_items_attributes: [:id, :item_image, :value, :description, :_destroy, :comment, :img_alt, :item_audio],
        question_images_attributes: [:id, :image, :legend, :img_alt, :_destroy],
        question_labels_attributes: [:id, :name, :_destroy],
        question_audios_attributes: [:id, :audio, :_destroy],
      ]
    )
  end

  def params_to_log
    { user_id: current_user.id, ip: get_remote_ip }
  end

  def log(object, message, type=LogAction::TYPE[:update])
    object.academic_allocations.each do |ac|
      LogAction.create(params_to_log.merge!(description: message, academic_allocation_id: ac.id, log_type: type))
    end
  end

  def build_exam_question
    if @exam_question.question.nil? 
      @exam_question.build_question do |q|
        q.question_images.build
        q.question_labels.build
        q.question_items.build
        q.question_audios.build
      end
    else
      @exam_question.question.question_images.build
      @exam_question.question.question_labels.build
      @exam_question.question.question_items.build
      @exam_question.question.question_audios.build
    end
  end

end
