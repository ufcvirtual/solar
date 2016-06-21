class LessonNotesController < ApplicationController

  include SysLog::Actions

  layout false

  def index
    if user_session[:blocking_content]
      render text: t('exams.restrict')
    else 
      @lesson_id    = params[:lesson_id]
      @lesson_notes = current_user.notes(@lesson_id).order(:name)
    end  
  end

  def show
    render partial: 'note', locals: { note: LessonNote.find(params[:id]) }
  end

  def edit
    @lesson_note = LessonNote.find(params[:id])
  end

  def new
    @lesson_note = LessonNote.new(lesson_id: params[:lesson_id])
  end

  def create_or_update
    note_params = params[:lesson_note]
    attributes  = { lesson_id: note_params[:lesson_id], name: note_params[:name], user_id: current_user.id }

    @lesson_note = params.include?(:id) ? LessonNote.find(params[:id]) : (current_user.nil? ? LessonNote.new(attributes) : LessonNote.where(attributes).first_or_initialize)
    
    @lesson_note.attributes = lesson_notes_params
    @lesson_note.save!

    render json: { success: true, notice: t('lesson_notes.success.created_updated'), url: lnote_path(@lesson_note) }
  rescue => error
    render_json_error(error, 'lesson_notes.error', 'general_message', (@lesson_note && @lesson_note.errors.any? ? @lesson_note.errors.full_messages.first : nil))
  end

  def destroy
    lesson_note = LessonNote.find(params[:id])
    raise 'permission' unless lesson_note.user_id == current_user.id
    lesson_note.destroy

    render json: { success: true, notice: t('lesson_notes.success.removed') }
  rescue => error
      render_json_error(error, 'lesson_notes.error')
  end

  def find
    note_params = params[:lesson_note]
    @note       = current_user.notes(note_params[:lesson_id], { name: note_params[:name] }).first

    render json: { success: true, content: (@note.nil? ? '' : @note.description) }
  rescue => error
    render json: { success: true, content: '' }
  end

  # require 'prawn'
  def download
    lesson = Lesson.find(params[:lesson_id])
    lesson_notes = params.include?(:id) ? [LessonNote.find(params[:id])] : current_user.notes(params[:lesson_id]).order(:name)

    info = lesson.offer.allocation_tag.info

    raise 'permission' unless lesson_notes.map(&:user_id).uniq == [current_user.id]

    name = []
    name << lesson.name
    name << lesson_notes.first.name if lesson_notes.size == 1

    name = name.join(' - ')

    pdf = Prawn::Document.new do 
      font('Helvetica', size: 8)

      fill_color '003E7A'
      fill_rectangle [0, cursor], 540, 80
      move_down 10
      image File.join(Rails.root.to_s, 'app', 'assets', 'images', 'logo.png'), position: :center, fit: [300, 300]

      move_down 50
      font_size(14){ 
        text  I18n.t('lesson_notes.index.title'), align: :center, color: 'DCA727', style: :bold
        move_down 10
        text info, align: :center
        move_down 10
        text [I18n.t('lesson_notes.pdf.lesson'), name].join(''), align: :center
      }
      move_down 50

      lesson_notes.each do |note|
        font_size(10){ text note.name, align: :center, style: :bold }
        dash(1, phase: 2)
        stroke_color '003E7A'
        stroke_horizontal_rule
        move_down 20
        text ActionController::Base.helpers.sanitize(note.description, tags: %w(strong em b i u br)), inline_format: true, color: '000000'
        move_down 50
      end
    end  

    send_data pdf.render, filename: name = [name, 'pdf'].join('.'), type: 'application/pdf'
  rescue => error
    redirect_to (request.referer.nil? ? home_url(only_path: false) : request.referer), alert: t('lesson_notes.error.pdf')
  end

  private

    def lesson_notes_params
      params.require(:lesson_note).permit(:name, :description)
    end
end
