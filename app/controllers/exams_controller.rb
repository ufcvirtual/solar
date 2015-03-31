class ExamsController < ApplicationController

  include SysLog::Actions

  layout false, except: :index

  before_filter :prepare_for_group_selection, only: :index
  #before_filter :get_groups_by_allocation_tags, only: [:new, :create]

  #before_filter only: [:edit, :update, :show] do |controller|
  #  get_groups_by_tool(@exam = Exam.find(params[:id]))
  #end

  def index
    @allocation_tags_id = active_tab[:url][:allocation_tag_id]
    authorize! :index, Exam, on: [@allocation_tags_id]
    @exams = Exam.my_exams(@allocation_tags_id)
  #rescue
    #render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

end