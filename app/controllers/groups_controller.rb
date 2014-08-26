class GroupsController < ApplicationController

  include SysLog::Actions

  layout false, except: [:index]

  # Mobilis
  def index
    @groups = current_user.groups

    if params.include?(:curriculum_unit_id)
      ucs_groups = CurriculumUnit.find(params[:curriculum_unit_id]).groups
      @groups = ucs_groups.select {|g| (ucs_groups.map(&:id) & @groups.map(&:id)).include?(g.id) }
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => @groups.map {|g| {id: g.id, code: g.code, semester: g.offer.semester.name} } }
      format.json  { render :json => @groups.map {|g| {id: g.id, code: g.code, semester: g.offer.semester.name} } }
    end
  end

  # SolarMobilis
  # GET /groups/listando.json
  def mobilis_list
     @groups = current_user.groups
    
    if params.include?(:curriculum_unit_id)
      @groups = CurriculumUnit.find(params[:curriculum_unit_id]).groups.where(id: @groups)
    end

    respond_to do |format|
      format.json { render json: { groups: @groups.map {|g| {id: g.id, code: g.code, semester: g.offer.semester.name} } } }
    end
  end

  # Edicao
  def list
    @type_id = params[:type_id].to_i
    offer    = Offer.find(params[:offer_id]) if params.include?(:offer_id)

    if offer.nil?
      query = []
      query << (params[:course_id].blank? ? "course_id IS NULL" : "course_id = #{params[:course_id]}")
      query << (@type_id == 3 ? nil : (params[:curriculum_unit_id].blank? ? "curriculum_unit_id IS NULL" : "curriculum_unit_id = #{params[:curriculum_unit_id]}"))
      offer = Offer.where(semester_id: params[:semester_id]).where(query.compact.join(" AND ")).first
    end

    authorize! :list, Group, on: [offer.allocation_tag.id] unless params[:checkbox]

    @groups, @offer_id = ( offer.nil? ? [] : offer.groups.order("code") ), offer.try(:id)
    render partial: 'groups_checkboxes', locals: { groups: @groups } if params[:checkbox]
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def new
    authorize! :create, Group
    @offer_id = params[:offer_id]
    @group = Group.new offer_id: @offer_id
  end

  def edit
    authorize! :update, Group
    @group, @type_id, @offer_id = Group.find(params[:id]), params[:type_id], params[:offer_id]
  end

  def create
    params[:group][:user_id] = current_user.id
    @group, @type_id, @offer_id = Group.new(params[:group]), params[:type_id], (params.include?(:offer_id) ? params[:offer_id] : params[:group][:offer_id])
    authorize! :create, Group, on: [@group.offer.allocation_tag.id]

    if @group.save
      render json: {success: true, notice: t(:created, scope: [:groups, :success])}
    else
      render :new
    end
  end

  def update
    @group, @type_id, @offer_id = Group.where(id: params[:id].split(",")), params[:type_id], (params.include?(:offer_id) ? params[:offer_id] : params[:group][:offer_id])
    authorize! :update, Group, on: [@group.first.offer.allocation_tag.id]

    if params[:multiple]
      @group.update_all(status: params[:status])
      render json: {success: true, notice: t(:updated, scope: [:groups, :success])}
    else
      @group = @group.first
      if @group.update_attributes(params[:group])
        render json: {success: true, notice: t(:updated, scope: [:groups, :success])}
      else
        render :edit
      end
    end
  end

  def destroy
    @group, @type_id, @offer_id = Group.where(id: params[:id].split(",")), params[:type_id], params[:offer_id]
    authorize! :destroy, Group, on: [@group.first.offer.allocation_tag.id]

    Group.transaction do 
      begin
        raise "erro" if @group.map(&:can_destroy?).include?(false)
        @group.destroy_all
        render json: {success: true, notice: t(:deleted, scope: [:groups, :success])}
      rescue => error
        render json: {success: false, alert: t(:deleted, scope: [:groups, :error])}, status: :unprocessable_entity
      end
    end
  end

  # desvincular/remover/adicionar turmas para determinada ferramenta
  def change_tool
    groups = Group.where(id: params[:id].split(","))
    authorize! :change_tool, Group, on: [groups.map(&:allocation_tag).map(&:id)]

    begin

      if params[:type] == "add"
        AcademicAllocation.transaction do
          AcademicAllocation.create! groups.map {|group| {allocation_tag_id: group.allocation_tag.id, academic_tool_id: params[:tool_id], academic_tool_type: params[:tool_type]}}
        end
      else
        group = groups.first
        academic_allocation = AcademicAllocation.where(allocation_tag_id: group.allocation_tag.id, academic_tool_type: params[:tool_type], academic_tool_id: params[:tool_id]).first

        tool_model = params[:tool_type].constantize
        tool = tool_model.find(params[:tool_id])

        raise "cant_transfer_dependencies" unless (not tool.respond_to?(:can_remove_or_unbind_group?) or tool.can_remove_or_unbind_group?(group))

        unless tool.groups.size == 1 # se não for a única turma
          case params[:type]
            when "unbind" # desvincular uma turma
              new_tool = tool_model.create(tool.attributes)
              academic_allocation.update_attribute(:academic_tool_id, new_tool.id)

              # se a ferramenta possuir um schedule, cria um igual para a nova
              new_tool.update_attribute(:schedule_id, Schedule.create(tool.schedule.attributes).id) if tool.respond_to?(:schedule)
              # copia as dependências pro novo objeto caso existam
              new_tool.copy_dependencies_from(tool) if new_tool.respond_to?(:copy_dependencies_from)
            when "remove" # remover uma turma
              academic_allocation.destroy
            else
              raise "option_not_found"
          end
        else # se for a única turma
          raise "last_group"
        end
      end

      render json: {success: true, notice: t("#{params[:type]}", scope: [:groups, :success])}
    rescue ActiveRecord::RecordNotSaved
      render json: {success: false, alert: t(:academic_allocation_already_exists, scope: [:groups, :error])}, status: :unprocessable_entity
    rescue => error
      error_message = I18n.translate!("#{error.message}", scope: [:groups, :error], :raise => true) rescue t("tool_change", scope: [:groups, :error])
      render json: {success: false, alert: error_message}, status: :unprocessable_entity
    end

  end

end
