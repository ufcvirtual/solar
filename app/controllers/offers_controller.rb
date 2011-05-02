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
    respond_to do |format|
      format.html
      format.xml  { render :xml => @offer }
    end
  end

  def new
    respond_to do |format|
      format.html
      format.xml  { render :xml => @offer }
    end
  end

  def edit
  end

  def create
    respond_to do |format|
      format.html
      format.xml  { render :xml => @offer }
    end
  end

  def update
    respond_to do |format|
      format.html
      format.xml  { render :xml => @offer }
    end
  end

  def destroy
    @offer.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

  def showoffersbyuser

    @types = CurriculumUnitType.order("description")
    @student_profile = student_profile

    if current_user && (student_profile != '')

      query_category = ""
      query_text = ""

      # consulta para matriculas ativas
      query_enroll =
        " SELECT DISTINCT of.id, cr.name as name, t.id AS categoryid, t.description AS categorydesc,
                 t.allows_enrollment, al.status AS status, al.id AS allocationid,
                 g.code, e.start, e.end, atg.id AS allocationtagid,
                 g.id AS groupsid, t.icon_name
            FROM allocations al
            JOIN allocation_tags atg      ON atg.id = al.allocation_tags_id
            JOIN groups g                 ON g.id = atg.groups_id
            JOIN offers of                ON of.id = g.offers_id
            JOIN curriculum_units cr      ON cr.id = of.curriculum_units_id
            JOIN curriculum_unit_types t  ON t.id = cr.curriculum_unit_types_id
       LEFT JOIN enrollments e            ON of.id = e.offers_id
           WHERE users_id = #{current_user.id}
             AND al.profiles_id = #{student_profile}"

      # recebe params[:offer] se foi pela pesquisa - MATRICULADOS e/ou ATIVOS
      if params[:offer]
        if params[:offer][:category]
          #reduz para determinada categoria de disciplina
          @search_category = params[:offer][:category]
          query_category = " and t.id=#{@search_category}" if !@search_category.empty?
        end
        if params[:offer][:search]
          @search_text = params[:offer][:search]
          query_text = " and cr.name ilike '%#{@search_text}%' " if !@search_text.empty?
        end
      end

      # se params[:category_query]=='enroll' traz apenas MATRICULADOS
      if params[:category_query]=='enroll'
        query_offer = "#{query_enroll} AND al.status = #{Allocation_Activated} ORDER BY name"

      else

        # traz todos: data de matricula ativa e q seja matriculavel + matriculados
        query_offer = "SELECT * FROM (
          SELECT DISTINCT of.id,cr.name as name, t.id as categoryid, t.description as categorydesc,
                 t.allows_enrollment, null::integer as status, null::integer as allocationid,
                 g.code, e.start, e.end, atg.id as allocationtagid,
                 g.id AS groupsid, t.icon_name
            FROM offers of
       LEFT JOIN enrollments e           ON of.id=e.offers_id
      INNER JOIN curriculum_units cr     ON of.curriculum_units_id = cr.id
      INNER JOIN curriculum_unit_types t ON t.id = cr.curriculum_unit_types_id
 LEFT OUTER JOIN courses c               ON of.courses_id = c.id
      INNER JOIN groups g                ON g.offers_id = of.id
      INNER JOIN allocation_tags atg     ON atg.groups_id = g.id
            WHERE
              (select enrollments.start from enrollments where of.id=enrollments.offers_id)<= current_date and
              (select enrollments.end from enrollments where of.id=enrollments.offers_id)>= current_date
              AND
              t.allows_enrollment = TRUE
              AND NOT EXISTS
                (  SELECT al.id
                     FROM allocations al
               INNER JOIN allocation_tags ON allocation_tags.id = al.allocation_tags_id
               INNER JOIN groups          ON groups.id = allocation_tags.groups_id
               INNER JOIN offers          ON offers.id = groups.offers_id
                    WHERE users_id = #{current_user.id}
                      AND offers.id=of.id
                )
              #{query_category}
              #{query_text}
             UNION
              #{query_enroll}
              #{query_category}
              #{query_text}
            ) AS offer_user
            ORDER BY name"
      end

      @user = User.find(current_user.id)
      @offers = Offer.find_by_sql(query_offer)

    else
      @offers = nil
    end
  end

end
