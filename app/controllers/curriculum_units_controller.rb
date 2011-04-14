class CurriculumUnitsController < ApplicationController


#  load_and_authorize_resource

  before_filter :require_user, :only => [:new, :edit, :create, :update, :destroy, :access, :class_responsible]


  def index
    #if current_user
    #  @user = CurriculumUnit.find(current_user.id)
    #end
    #render :action => :mysolar

    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @users }
    #end
  end

  def show
    @curriculum_unit = CurriculumUnit.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @curriculum_unit }
    end
  end

  def new
    @curriculum_unit = CurriculumUnit.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @curriculum_unit }
    end
  end

  def edit
    @curriculum_unit = CurriculumUnit.find(params[:id])
  end

  def create
    @curriculum_unit = CurriculumUnit.new(params[:user])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @curriculum_unit }
    end
  end

  def update
    @curriculum_unit = CurriculumUnit.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @curriculum_unit }
    end
  end

  def destroy
    @curriculum_unit = CurriculumUnit.find(params[:id])
    @curriculum_unit.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

  def access
    #localiza unidade curricular
    @curriculum_unit = CurriculumUnit.find (params[:id])

    #retorna responsaveis
    @responsible = class_responsible

    if current_user
      @user = User.find(current_user.id)
    end
  end

  # Retorna responsaveis por unidade curricular passada que tenham status ativo
  #   o perfil responsavel esta marcado na tabela profiles (pode ser mais de um)
  #   busca em allocation_tags groups e offers relacionadas a unidade curricular
  def class_responsible
      curriculum_unit = params[:id]

      if curriculum_unit
          responsible = User.find(:all,
            :select => "DISTINCT users.id, users.name as username, users.email, profiles.name as profilename ",
            :joins => "inner join allocations on allocations.users_id = users.id
                       inner join profiles on allocations.profiles_id = profiles.id
                       inner join allocation_tags on allocations.allocation_tags_id = allocation_tags.id",
            :conditions => "profiles.class_responsible = TRUE and
                      allocations.status=#{Allocation_Activated} and
                      (
                       allocation_tags.curriculum_units_id=#{curriculum_unit} or
                       allocation_tags.offers_id in (select id from offers where curriculum_units_id=#{curriculum_unit}) or
                       allocation_tags.groups_id in (select groups.id from groups
                                       inner join offers on groups.offers_id=offers.id
                                       where curriculum_units_id=#{curriculum_unit})
                      )",
            :order => "profilename, users.name"
          )
          return responsible
      else
          return nil
      end
  end

end
