class QuestionsController < ApplicationController

  include SysLog::Actions

  before_action :set_current_user, only: [:destroy, :change_status, :verify_owners, :copy]

  layout false, except: :index

  require 'will_paginate/array'
  def index
    authorize! :index, Question
    @questions = Question.get_all(current_user.id, @search=(params[:search] || {}), @verify_privacy=params[:verify_privacy]).paginate(page: params[:page], per_page: 15)
    @can_see_preview = can? :show, Question
    respond_to do |format|
      if params[:search].nil? && params[:replace].blank?
        format.html
      else
        format.html { render partial: 'questions/questions' }
      end
      format.js
    end
  end

  def new
    @question = Question.new
    @question.question_images.build
    @question.question_labels.build
    @question.question_items.build
    @question.question_audios.build
  end

  def create
    authorize! :create, Question
    @question         = Question.new question_params
    @question.user_id = current_user.id
    @can_see_preview = true

    if !params['question_texts']['text'].blank?
      @question.build_question_text(text: params['question_texts']['text'])
    end

    if @question.save
      render partial: 'question', locals: { question: @question }
    else
      @errors = []
      @question.errors.each do |attribute, erro|
        @object = "question_"+attribute.to_s
      end  
      render json: { success: false, alert: @question.errors.full_messages.join(', '), object: @object.gsub('.', '_') }, status: :unprocessable_entity
    end

  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'questions.error')
  end

  def change_status
    authorize! :change_status, Question
    ids = params[:id].split(',') rescue [params[:id]]
    @questions = Question.where(id: ids)
    ActiveRecord::Base.transaction do
      @questions.each do |question|
        question.can_change_status?
        question.update_attributes status: (params[:status].nil? ? !question.status : params[:status])
      end
    end

    render json: { success: true, notice: t('questions.success.change_status') }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'questions.error')
  end

  def edit
    @question = Question.find(params[:id])
    @question.question_images.build
    @question.question_labels.build
    @question.question_items.build
    @question.question_audios.build
    @question_text = @question.question_text
  end

  def update
    authorize! :update, Question
    @question         = Question.find params[:id]

    if !params['question_texts']['text'].blank?
      @question.question_text.text = params['question_texts']['text']
      @question_text = @question.question_text
      @question_text.save
    end

    if @question.update_attributes question_params
      render partial: 'question', locals: { question: @question }
    else
      @errors = []
      @question.errors.each do |attribute, erro|
        @object = "question_"+attribute.to_s
      end  
      render json: { success: false, alert: @question.errors.full_messages.join(', '), object: @object.gsub('.', '_')  }, status: :unprocessable_entity
    end

  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'questions.error')
  end

  def destroy
    authorize! :destroy, Question
    ActiveRecord::Base.transaction do
      Question.where(id: params[:id].split(',')).each do |question|
        question.destroy
      end
    end
    render json: { success: true, notice: t('questions.success.deleted') }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'questions.error')
  end

  def show
    @can_see_preview = can? :show, Question
    raise CanCan::AccessDenied unless @can_see_preview
    @question = Question.find params[:id]
    @question.can_see?
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'questions.error')
  end

  def verify_owners
    question = Question.find params[:id]
    if params[:update]
      question.can_change?
      authorize! :update, Question
    end
    if params[:copy]
      question.can_copy?
      authorize! :copy, Question
    end
    if params[:show]
      question.can_see?    if params[:show]
      authorize! :show, Question
    end

    render json: { success: true }
  rescue => error
    render_json_error(error, 'questions.error')
  end

  def copy
    authorize! :copy, Question

    question  = Question.find params[:id]
    question.can_copy?

    @question = Question.copy(question, current_user.id)

    log(question, "question: #{question.id} [copy], #{question.log_description}", LogAction::TYPE[:create]) rescue nil

    @question.question_images.build
    @question.question_labels.build
    @question.question_items.build
    @question.question_audios.build

    render :edit
  end

  private

  def question_params
    params.require(:question).permit(:enunciation, :type_question, :privacy,
      question_items_attributes: [:id, :item_image, :value, :description, :_destroy, :comment, :img_alt, :item_audio, :audio_description],
      question_images_attributes: [:id, :image, :legend, :img_alt, :_destroy],
      question_labels_attributes: [:id, :name, :_destroy],
      question_audios_attributes: [:id, :audio, :description, :audio_description, :_destroy])
  end

  def params_to_log
    { user_id: current_user.id, ip: get_remote_ip }
  end

  def log(object, message, type=LogAction::TYPE[:update])
    LogAction.create(params_to_log.merge!(description: message, log_type: type))
  end

end
