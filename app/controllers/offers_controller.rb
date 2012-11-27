include ApplicationHelper
include OffersHelper

class OffersController < ApplicationController

  def index
    # não poderão vir com o valor 0 (indicando que "nenhum" foi selecionado, pois as ofertas dependem de ambos)
    @course_id, @curriculum_unit_id = (params[:course_id] || "all"), (params[:curriculum_unit_id] || "all") # a fim de testes: editor, atualmente, tem permissão para uc: 3 e curso: 2
    authorize! :index, Offer, :on => get_allocations_tags(nil, @curriculum_unit_id, @course_id) # verifica se tem acesso aos uc e cursos selecionados
    get_offers(@curriculum_unit_id, @course_id)
  end

  def new
    @curriculum_unit_id, @course_id = params[:curriculum_unit_id], params[:course_id]
    authorize! :new, Offer, :on => get_allocations_tags(nil, @curriculum_unit_id, @course_id) # verifica se tem acesso aos uc e curso selecionados

    @offer = Offer.new
    render :layout => false
  end

  def edit
    @curriculum_unit_id, @course_id = params[:curriculum_unit_id], params[:course_id]
    @offer = Offer.find(params[:id])

    authorize! :edit, Offer, :on => [@offer.allocation_tag.id] # verifica se tem acesso à oferta a ser editada
    render :layout => false
  end

  # Método que, a partir das ucs e cursos selecionados, cria ofertas para todas as combinações possíveis entre aqueles
  def create
    params[:offer][:curriculum_unit_id], params[:offer][:course_id] = CurriculumUnit.first, Course.first # valores aleatórios utilizados apenas para testar a validade da oferta
    params[:offer][:user_id] = current_user.id # para a alocação
    @offer = Offer.new(params[:offer])

    @curriculum_unit_id, @course_id = params[:curriculum_unit_id], params[:course_id]
    get_curriculum_units_and_courses(@curriculum_unit_id, @course_id)

    begin
      
      authorize! :create, Offer, :on => get_allocations_tags(nil, @curriculum_unit_id, @course_id) # verifica se tem acesso aos uc e curso selecionados
      raise "erro" unless @offer.valid? # utilizado para validar os campos preenchidos e exibir erros quando necessário

      @courses.each do |course| # lista de cursos dependendo do que foi selecionado previamente 
        @curriculum_units.each do |curriculum_unit| # lista de ucs dependendo do que foi selecionado previamente 
          params[:offer][:curriculum_unit_id], params[:offer][:course_id] = curriculum_unit.id, course.id
          offer = Offer.create!(params[:offer]) # cria uma oferta para cada combinação de uc e curso
        end
      end

      respond_to do |format|
        get_offers(@curriculum_unit_id, @course_id)
        format.html { render :index, :layout => false }
      end

    rescue CanCan::AccessDenied

      respond_to do |format|
        get_offers(@curriculum_unit_id, @course_id)
        @access_denied = true
        format.html { render :index, :layout => false }
      end

    rescue Exception => error

      respond_to do |format|
        @date_range_error = @offer.errors.full_messages.last unless @offer.errors[:start_date].blank? and @offer.errors[:end_date].blank?
        format.html { render :new, :layout => false }
      end

    end

  end

  def update
    @offer = Offer.find(params[:id])
    authorize! :update, Offer, :on => [@offer.allocation_tag.id] # verifica se tem acesso à oferta a ser editada

    params[:offer][:curriculum_unit_id], params[:offer][:course_id] = @offer.curriculum_unit_id, @offer.course_id
    @curriculum_unit_id, @course_id = params[:curriculum_unit_id], params[:course_id]

    begin

      @offer.update_attributes!(params[:offer])
      respond_to do |format|
        get_offers(params[:curriculum_unit_id], params[:course_id])
        format.html { render :index, :layout => false }
      end

    rescue Exception => error
      respond_to do |format|
        @date_range_error = @offer.errors.full_messages.last unless @offer.errors[:start_date].blank? and @offer.errors[:end_date].blank?
        format.html { re__nder :edit, :layout => false }
      end

    end
  end

  def destroy
    offer = Offer.find(params[:id])
    @course_id, @curriculum_unit_id = params[:course_id], params[:curriculum_unit_id]

    begin
      authorize! :destroy, Offer, :on => [offer.allocation_tag.id] # verifica se tem acesso à oferta a ser excluída
      offer.destroy
    rescue CanCan::AccessDenied
      @access_denied = true
    rescue Exception => error
      @error_deletion = t(:not_possible_to_delete, :scope => [:offers])
    end

    respond_to do |format|
      get_offers(@curriculum_unit_id, @course_id)
      format.html { render :index, :layout => false }
    end
  end

  # Método que desabilita todos os grupos da oferta
  def deactivate_groups
    offer = Offer.find(params[:id])
    authorize! :deactivate_groups, Offer, :on => [offer.allocation_tag.id] # verifica se tem acesso à oferta a ter suas turmas desativadas

    offer.groups.each { |group| group.update_attributes!(:status => false) }

    respond_to do |format|
      @curriculum_unit_id, @course_id = params[:curriculum_unit_id], params[:course_id]
      get_offers(@curriculum_unit_id, @course_id)
      format.html {render :index, :layout => false}
    end
  end

end