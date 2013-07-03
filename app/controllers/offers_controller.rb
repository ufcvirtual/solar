class OffersController < ApplicationController

  include ApplicationHelper
  include OffersHelper

  layout false

  def new
    authorize! :new, Offer

    params[:format] = :html
    @offer = Semester.find(params[:semester_id]).offers.build course_id: params[:course_id], curriculum_unit_id: params[:curriculum_unit_id]

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
    optional_authorize(:create)

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
    optional_authorize(:update)

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
    authorize! :destroy, offer

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

  private

    def optional_authorize(method)
      at_c = params[:offer][:course_id].blank? ? nil : AllocationTag.find_by_course_id(params[:offer][:course_id]).id
      at_uc = params[:offer][:curriculum_unit_id].blank? ? nil : AllocationTag.find_by_curriculum_unit_id(params[:offer][:curriculum_unit_id]).id

      # os dados de uc e curso podem ser modificados
      begin
        raise if at_c.nil? # a oferta obriga uc OU c, mas nao ambos
        authorize! method, Offer, on: [at_c].compact
      rescue
        authorize! method, Offer, on: [at_uc].compact
      end
    end

end
