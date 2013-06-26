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
    @offer = Offer.new
  end

  def edit
    @offer = Offer.find(params[:id])
    authorize! :edit, @offer, on: [@offer.allocation_tag.id]
  end

  def create
    @offer = Offer.new params[:offer]
    authorize! :create, Offer, on: [@offer.curriculum_unit.try(:allocation_tag).try(:id), @offer.course.try(:allocation_tag).try(:id)].compact

    begin
      Offer.transaction do
        @offer.offer_schedule = Schedule.create!(params[:offer_schedule]) if params.include?(:offer_schedule)
        @offer.enrollment_schedule = Schedule.create!(params[:enrollment_schedule]) if params.include?(:enrollment_schedule)

        @offer.save!
      end

      render json: {success: true}
    rescue
      render :new
    end
  end

  def update
    @offer = Offer.find(params[:id])
    authorize! :update, @offer, on: [@offer.allocation_tag.id]

    begin
      Offer.transaction do
        @offer.update_attributes(params[:offer]) if params.include?(:offer)

        if params.include?(:offer_schedule)
          if @offer.offer_schedule.nil?
            @offer.offer_schedule = Schedule.create!(params[:offer_schedule])
          else
            @offer.offer_schedule.update_attributes!(params[:offer_schedule])
          end
        end

        if params.include?(:enrollment_schedule)
          if @offer.enrollment_schedule.nil?
            @offer.enrollment_schedule = Schedule.create!(params[:enrollment_schedule])
          else
            @offer.enrollment_schedule.update_attributes!(params[:enrollment_schedule])
          end
        end

        @offer.save!
      end

      render json: {success: true}
    rescue
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
