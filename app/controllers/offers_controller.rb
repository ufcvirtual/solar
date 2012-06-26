include ApplicationHelper

class OffersController < ApplicationController

  before_filter :get_values, :only => [:new, :edit]

  def index
    @offers = Offer.find(:all, :order => 'semester desc')

#    return User.find(:all,
#      :joins => "INNER JOIN user_messages ON users.id = user_messages.user_id",
#      :select => "users.*",
#      :conditions => "user_messages.message_id = #{message_id} AND NOT cast( user_messages.status & '#{Message_Filter_Sender.to_s(2)}' as boolean)")

    respond_to do |format|
      format.html # index.html.erb
      #format.xml  { render :xml => @users }
    end
  end

  def new
    @offer = Offer.new
    @start_date = l Date.today
    @end_date = l Date.today
  end

  def edit
    @offer = Offer.find(params[:id])
    @start_date = l @offer.start
    @end_date = l @offer.end
  end

  def create
    @offer = Offer.new(
          :course_id => params[:course_id],
          :curriculum_unit_id => params[:curriculum_unit_id],
          :semester => params[:offer][:semester],
          :start => params[:offer][:start],
          :end => params[:offer][:end]
    )

    respond_to do |format|
      if @offer.save
        format.html { redirect_to(offers_url) }
        format.xml  { render :xml => @offer }
      else
        format.html
        format.xml
      end
    end
  end

  def update
    offer = Offer.find(params[:id])

    respond_to do |format|
      if offer.update_attributes(params[:offer])
        format.html { redirect_to(offers_url) }
        format.xml  { render :xml => @offer }
      else
        format.html
        format.xml
      end
    end
  end

  # GET /offers/1
  # GET /offers/1.json
  def show
    @offer = Offer.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @offer }
    end
  end

  # DELETE /offers/1
  # DELETE /offers/1.json
  def destroy
    offer = Offer.find(params[:id])
    offer.destroy

    respond_to do |format|
      format.html { redirect_to(offers_url) }
      format.xml  { head :ok }
    end
  end

  private

  def get_values
    @courses = Course.find(:all)
    @curriculum_units = CurriculumUnit.find(:all)
  end

end
