include ApplicationHelper

class OffersController < ApplicationController

  def index
    @offers = Offer.find(:all)

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

    respond_to do |format|
      format.html
      format.xml  { render :xml => @offer }
    end
  end

  def edit
    @offer = Offer.find(params[:id])
  end

  def create
    @offer = Offer.new(params[:offer])

    #respond_to do |format|
      if @offer.save

      else

      end
    #end
    respond_to do |format|
      format.html
      format.xml  { render :xml => @offer }
    end
  end

  def update
    @offer = Offer.find(params[:id])

    #respond_to do |format|
      if @offer.update_attributes(params[:offer])

      else

      end
    #end
    respond_to do |format|
      format.html
      format.xml  { render :xml => @offer }
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

  def destroy
    @offer.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Oferta excluida com sucesso!') }
      format.xml  { head :ok }
    end
  end

end
