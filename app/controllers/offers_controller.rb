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
    @allocation_tags_ids = current_user.allocation_tags_ids_with_access_on([:update, :destroy], "offers").join(" ")
    @offers   = @semester.offers_by_allocation_tags(@allocation_tags_ids.split(" "),
      {curriculum_units: {curriculum_unit_type_id: @type_id}, course_id: params[:course_id], curriculum_unit_id: params[:curriculum_unit_id]})
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
  rescue => error
    request.format = :json
    raise error.class
  end

  def update
    @type_id =  params[:offer][:type_id].to_i
    @offer   = Offer.find(params[:id])

    optional_authorize(:update)

    if @offer.update_attributes!(offer_params)
      render json: {success: true, notice: t(:updated, scope: [:offers, :success])}
    else
      @offer.build_period_schedule if @offer.period_schedule.nil?
      @offer.build_enrollment_schedule if @offer.enrollment_schedule.nil?

      render :edit
    end
  end

  def destroy
    @offers = Offer.where(id: params[:id].split(",").flatten)
    authorize! :destroy, Offer, on: @offers.map(&:allocation_tag).map(&:id)

    @offers.destroy_all

    render json: {success: true, notice: t('offers.success.deleted')}
  rescue ActiveRecord::DeleteRestrictionError
    render json: {success: false, alert: t('offers.error.deleted')}, status: :unprocessable_entity
  rescue => error
    request.format = :json
    raise error.class
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
      at_c  = AllocationTag.find_by_course_id(params[:offer][:course_id]).try(:id)                   unless params[:offer][:course_id].blank?
      at_uc = AllocationTag.find_by_curriculum_unit_id(params[:offer][:curriculum_unit_id]).try(:id) unless params[:offer][:curriculum_unit_id].blank?

      if at_c.nil? and at_uc.nil?
        authorize! method, Offer
      else
        begin
          authorize! method, Offer, on: [at_c]
        rescue
          authorize! method, Offer, on: [at_uc]
        end
      end
    end
end
