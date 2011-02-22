class OffersController < ApplicationController
  
  def index
    #if current_user
    #  @user = Offer.find(current_user.id)
    #end
    #render :action => :mysolar

    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @users }
    #end
  end

  def show
    @offer = Offer.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @offer }
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
    @offer = Offer.new(params[:user])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @offer }
    end
  end

  def update
    @offer = Offer.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @offer }
    end
  end

  def destroy
    @offer = Offer.find(params[:id])
    @offer.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

  def showoffersbyuser
    if current_user
      @user = User.find(current_user.id)
      @offers = Offer.find(:all,
        :select => "offers.id,curriculum_unities.name, curriculum_unities.category,
                   groups.code, allocations.status, enrollments.start, enrollments.end",
        :joins => "LEFT JOIN enrollments ON offers.id=enrollments.offers_id and (enrollments.start <= current_date and enrollments.end >= current_date)
                   INNER JOIN curriculum_unities  ON offers.curriculum_unities_id = curriculum_unities.id
                   LEFT OUTER JOIN courses  ON offers.courses_id = courses.id
                   INNER JOIN groups  ON groups.offers_id = offers.id
                   LEFT JOIN allocations  ON allocations.groups_id = groups.id AND allocations.users_id = #{current_user.id} AND allocations.profiles_id = 1"
      )
    end
  end

end
