class OffersController < ApplicationController


  load_and_authorize_resource
  #  skip_authorize_resource :only => :showoffersbyuser

  before_filter :require_user, :only => [:new, :edit, :create, :update, :destroy, :showoffersbyuser]


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

    @types = CurriculumUnitType.order("description")
    @student_profile = student_profile

    if current_user && (student_profile!='')

      query_date_enrollment = ""
      query_category = ""
      query_text = ""

      if params[:category_query]!='enroll'
        #traz todos: matriculados OU com data de matricula ativa e q seja dos tipos: free, extension, presential
        query_date_enrollment = "((select enrollments.start from enrollments where offers.id=enrollments.offers_id)<= current_date and
                                  (select enrollments.end from enrollments where offers.id=enrollments.offers_id)>= current_date
                                   and curriculum_unit_types.allows_enrollment = TRUE
                                 ) or "
      end
      if params[:offer]
        query_date_enrollment = "((select enrollments.start from enrollments where offers.id=enrollments.offers_id)<= current_date and
                                  (select enrollments.end from enrollments where offers.id=enrollments.offers_id)>= current_date
                                  and curriculum_unit_types.allows_enrollment = TRUE
                                 ) or "

        if params[:offer][:category]
          #reduz para determinada categoria de disciplina
          @search_category = params[:offer][:category]
          query_category = " and curriculum_unit_types.id=#{@search_category}" if !@search_category.empty?
        end
        if params[:offer][:search]
          @search_text = params[:offer][:search]
          query_text = " and curriculum_units.name ilike '%#{@search_text}%' " if !@search_text.empty?
        end
      end

      @user = User.find(current_user.id)
      @offers = Offer.find(:all,
        :select => "DISTINCT offers.id,curriculum_units.name, curriculum_unit_types.id as categoryid, curriculum_unit_types.description as categorydesc, curriculum_unit_types.allows_enrollment,
                   groups.code, allocations.status, enrollments.start, enrollments.end, allocation_tags.id as allocationtagid,
                   allocations.id AS allocationid, groups.id AS groupsid",
        :joins => "LEFT JOIN enrollments ON offers.id=enrollments.offers_id
                   INNER JOIN curriculum_units  ON offers.curriculum_units_id = curriculum_units.id
                   INNER JOIN curriculum_unit_types on curriculum_unit_types.id = curriculum_units.curriculum_unit_types_id
                   LEFT OUTER JOIN courses  ON offers.courses_id = courses.id
                   INNER JOIN groups  ON groups.offers_id = offers.id
                   INNER JOIN allocation_tags ON allocation_tags.groups_id = groups.id
                   LEFT OUTER JOIN allocations ON allocations.allocation_tags_id = allocation_tags.id",
        :conditions => "(
                  #{query_date_enrollment}
                  (allocations.users_id = #{current_user.id} AND allocations.profiles_id = #{student_profile} AND allocations.status = #{Allocation_Activated})
                  ) #{query_category} #{query_text}" ,
        :order => "curriculum_units.name"
      )
    else
      @offers = nil
      if current_user
        @user = User.find(current_user.id)
      end
    end
  end

end
