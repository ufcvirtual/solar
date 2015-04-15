class ExamsController < ApplicationController

  include SysLog::Actions

  layout false, except: :index
  before_filter :prepare_for_group_selection, only: :index
  before_filter :get_groups_by_allocation_tags, only: [:new, :create]

  def index
    @allocation_tags_id = active_tab[:url][:allocation_tag_id]
    authorize! :index, Exam, on: [@allocation_tags_id]
    @exams = Exam.my_exams(@allocation_tags_id)
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def new
    authorize! :create, Exam, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @exam = Exam.new
    @exam.build_schedule(start_date: Date.today, end_date: Date.today)
  end

  def create
    authorize! :create, Exam, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @exam = Exam.new exam_params
    @exam.allocation_tag_ids_associations = @allocation_tags_ids.split(' ').flatten

    if @exam.save
      render_notification_success_json('created')
    else
      render :new
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def list
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :list, Exam, { on: @allocation_tags_ids }

    @all_groups = Group.where(offer_id: params[:offer_id])
    @academic_allocations = Exam.academic_allocations_by_ats(@allocation_tags_ids.split(' '), page: params[:page])
  rescue
    render nothing: true, status: 500
  end


  private

  def exam_params
    params.require(:exam).permit(:name, :description, :duration, :start_hour, :end_hour,
                                      schedule_attributes: [:id, :start_date, :end_date])
  end

  def render_notification_success_json(method)
    render json: {success: true, notice: t(method, scope: 'exams.success')}
  end

end