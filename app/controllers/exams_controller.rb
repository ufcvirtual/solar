class ExamsController < ApplicationController

  include SysLog::Actions

  layout false, except: :index

  before_filter :prepare_for_group_selection, only: :index
  #before_filter :get_groups_by_allocation_tags, only: [:new, :create]

  #before_filter only: [:edit, :update, :show] do |controller|
  #  get_groups_by_tool(@discussion = Discussion.find(params[:id]))
  #end

  def index
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    #authorize! :index, Exam, on: @allocation_tags_ids

    @exams = Exam.joins(:schedule, academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).uniq.select("exams.*, schedules.start_date AS start_date").order("start_date")

  #rescue
    #render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

end