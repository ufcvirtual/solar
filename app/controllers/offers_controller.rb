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
      query_text = ""

      if params[:category_query]!='enroll'
        #traz todos: matriculados OU com data de matricula ativa e q seja dos tipos: free, extension, presential
        query_date_enrollment = "((select enrollments.start from enrollments where offers.id=enrollments.offers_id)<= current_date and
                                  (select enrollments.end from enrollments where offers.id=enrollments.offers_id)>= current_date
                                  and curriculum_unities.category in (#{Free_Course},#{Extension_Course},#{Presential_Undergraduate_Course},#{Presential_Graduate_Course})
                                 ) or "
      end
      if params[:offer]
        query_date_enrollment = "((select enrollments.start from enrollments where offers.id=enrollments.offers_id)<= current_date and
                                  (select enrollments.end from enrollments where offers.id=enrollments.offers_id)>= current_date
                                  and curriculum_unities.category in (#{Free_Course},#{Extension_Course},#{Presential_Undergraduate_Course},#{Presential_Graduate_Course})
                                 ) or "
        
        if params[:offer][:category]
          #reduz para determinada categoria de disciplina
          @search_category = params[:offer][:category]
          query_category = " and curriculum_unities.category=#{@search_category}" if !@search_category.empty?
        end
        if params[:offer][:search]
          @search_text = params[:offer][:search]
          query_text = " and curriculum_unities.name ilike '%#{@search_text}%' " if !@search_text.empty?
        end
      end

      @user = User.find(current_user.id)
      @offers = Offer.find(:all,
        :select => "DISTINCT offers.id,curriculum_unities.name, curriculum_unities.category,
                   groups.code, allocations.status, enrollments.start, enrollments.end, 
                   allocations.id AS allocationid, groups.id AS groupsid",
        :joins => "LEFT JOIN enrollments ON offers.id=enrollments.offers_id
                   INNER JOIN curriculum_unities  ON offers.curriculum_unities_id = curriculum_unities.id
                   LEFT OUTER JOIN courses  ON offers.courses_id = courses.id
                   INNER JOIN groups  ON groups.offers_id = offers.id
                   LEFT JOIN allocations  ON allocations.groups_id = groups.id",
        :conditions => "(
                  #{query_date_enrollment}
                  (allocations.users_id = #{current_user.id} AND allocations.profiles_id = #{Student} AND allocations.status = #{Allocation_Activated})
                  ) #{query_category} #{query_text}" ,
        :order => "curriculum_unities.name"
      )
    end
  end

end
