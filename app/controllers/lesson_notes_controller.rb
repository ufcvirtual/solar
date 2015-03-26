class LessonNotesController < ApplicationController

  include SysLog::Actions

  layout false

  def index
    @lesson_id    = params[:lesson_id]
    @lesson_notes = current_user.notes(@lesson_id).order(:name)
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
    ats = case 
          when active_tab[:url][:allocation_tag_id] then [active_tab[:url][:allocation_tag_id]]
          when params[:groups_by_offer_id].present? then AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id])
          else
            params[:allocation_tags_ids]
          end

    note_params  = params[:lesson_note]

    params[:lesson_note][:lesson_id] = Lesson.all_by_ats(ats, { name: lesson_note[:lesson_name] }).first.id unless note_params.include?(:lesson_id)


    @lesson_note = params.include?(:id) ? LessonNote.find(params[:id]) : LessonNote.where(lesson_id: note_params[:lesson_id], name: note_params[:name]).first_or_initialize
    
    if @lesson_note.update_attributes(lesson_notes_params.merge!(user_id: current_user.id))
      render json: { success: true, notice: t('lesson_notes.success.created_updated'), url: lnote_path(@lesson_note) }
    else
      raise 'description'
    end

  rescue => error
    render_json_error(error, "lesson_notes.error")
  end

  def destroy
    lesson_note = LessonNote.find(params[:id])
    raise 'permission' unless lesson_note.user_id == current_user.id
    lesson_note.destroy

    render json: { success: true, notice: t('lesson_notes.success.removed') }
  rescue => error
      render_json_error(error, "lesson_notes.error")
  end

  def download
    # todos ou individual
  end

  private

    def lesson_notes_params
      params.require(:lesson_note).permit(:name, :description)
    end
end
