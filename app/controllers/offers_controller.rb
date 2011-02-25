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
      query_date_enrollment = ""
      query_category = ""

      if params[:category_query]!='enroll'
        #traz todos: matriculados ou com data de matricula ativa
        query_date_enrollment = "((select enrollments.start from enrollments where offers.id=enrollments.offers_id)<= current_date and
                                  (select enrollments.end from enrollments where offers.id=enrollments.offers_id)>= current_date) or "
      end
      if params[:offer]
        query_date_enrollment = "((select enrollments.start from enrollments where offers.id=enrollments.offers_id)<= current_date and
                                  (select enrollments.end from enrollments where offers.id=enrollments.offers_id)>= current_date) or "
        if params[:offer][:category]
          #reduz para determinada categoria de disciplina          
          query_category = " and curriculum_unities.category=#{params[:offer][:category]}" if !params[:offer][:category].empty?
        end
      end

      @user = User.find(current_user.id)
      @offers = Offer.find(:all,
        :select => "offers.id,curriculum_unities.name, curriculum_unities.category,
                   groups.code, allocations.status, enrollments.start, enrollments.end",
        :joins => "LEFT JOIN enrollments ON offers.id=enrollments.offers_id
                   INNER JOIN curriculum_unities  ON offers.curriculum_unities_id = curriculum_unities.id
                   LEFT OUTER JOIN courses  ON offers.courses_id = courses.id
                   INNER JOIN groups  ON groups.offers_id = offers.id
                   LEFT JOIN allocations  ON allocations.groups_id = groups.id",
        :conditions => "(
                  #{query_date_enrollment}
                  (allocations.users_id = #{current_user.id} AND allocations.profiles_id = #{Student})
                  ) #{query_category}"
      )
    end
  end

end
