class OffersController < ApplicationController

  include ApplicationHelper
  include OffersHelper

  layout false

  def new
    @course, @uc = params[:course_id], params[:curriculum_unit_id]

    query = []
    query << "course_id = #{@course}" unless @course.nil?
    query << "curriculum_unit_id = #{@uc}" unless @uc.nil?

    if query.empty?
      authorize! :new, Offer
    else
      authorize! :new, Offer, on: AllocationTag.where(query).map(&:id)
    end

    params[:format] = :html
    @offer = Semester.find(params[:semester_id]).offers.build course_id: @course, curriculum_unit_id: @uc

    @offer.build_period_schedule
    @offer.build_enrollment_schedule
  end

  def edit
    @offer = Offer.find(params[:id])
    authorize! :edit, @offer, on: [@offer.allocation_tag.id]

    @offer.build_period_schedule if @offer.period_schedule.nil?
    @offer.build_enrollment_schedule if @offer.enrollment_schedule.nil?
  end

  def create
    @offer = Offer.new params[:offer]
    authorize! :create, Offer, on: [@offer.curriculum_unit.try(:allocation_tag).try(:id), @offer.course.try(:allocation_tag).try(:id)].compact

    # periodo de oferta e matricula ficam no semestre \ esses dados ficam na tabela de oferta apenas se diferirem dos dados do semestre
    @offer.period_schedule.try(:destroy) if @offer.period_schedule.try(:start_date).nil?
    @offer.enrollment_schedule.try(:destroy) if @offer.enrollment_schedule.try(:start_date).nil?

    if @offer.save
      render json: {success: true}
    else
      render :new
    end
  end

  def update
    @offer = Offer.find(params[:id])
    authorize! :update, @offer, on: [@offer.allocation_tag.id]

    begin
      Offer.transaction do
        if params[:offer].include?(:period_schedule_attributes) and params[:offer][:period_schedule_attributes][:start_date].blank? and params[:offer][:period_schedule_attributes][:end_date].blank?
          params[:offer].delete(:period_schedule_attributes)

          schedule = @offer.period_schedule
          @offer.period_schedule = nil
          schedule.destroy unless schedule.nil?
        end

        if params[:offer].include?(:enrollment_schedule_attributes) and params[:offer][:enrollment_schedule_attributes][:start_date].blank? and params[:offer][:enrollment_schedule_attributes][:end_date].blank?
          params[:offer].delete(:enrollment_schedule_attributes)

          schedule = @offer.enrollment_schedule
          @offer.enrollment_schedule = nil
          schedule.destroy unless schedule.nil?
        end

        @offer.update_attributes!(params[:offer])
      end

      redirect_to semesters_path, notice: 'Offer was successfully updated.'
      # render json: {success: true}
    rescue Exception => e
      @offer.build_period_schedule if @offer.period_schedule.nil?
      @offer.build_enrollment_schedule if @offer.enrollment_schedule.nil?

      render :edit
    end
  end

  def destroy
    offer = Offer.find(params[:id])
    authorize! :destroy, offer, on: [offer.allocation_tag.id]

    if offer.destroy
      flash[:notice] = t(:deleted_success, scope: :offers)
      render json: {success: true}
    else
      flash[:alert] = t(:not_possible_to_delete, scope: :offers)
      render json: {success: false}, status: :unprocessable_entity
    end

  end

  def deactivate_groups
    offer = Offer.find(params[:id])
    authorize! :deactivate_groups, Offer, on: [offer.allocation_tag.id]

    begin 
      offer.groups.map { |group| group.update_attributes!(status: false) }

      flash[:notice] = t(:all_groups_deactivated, scope: [:offers, :index])
      render json: {success: true}
    rescue
      flash[:alert] = t(:cant_deactivate, scope: [:offers, :index])
      render json: {success: false}, status: :unprocessable_entity
    end
  end

end
