class TabsController < ApplicationController

  before_filter :clear_breadcrumb_home, only: [:show, :create]
  before_filter :log_access, only: :create

  def show # activate
    # verifica se a aba que esta sendo acessada esta aberta
    redirect = home_path
    unless user_session[:tabs][:opened].has_key?(params[:name])
      set_active_tab_to_home # o usuário é redirecionado para o Home caso a aba não exista
    else
      set_active_tab(params[:name])
      # dentro da aba, podem existir links abertos
      redirect = active_tab[:breadcrumb].last[:url] if active_tab[:url][:context].to_i == Context_Curriculum_Unit.to_i
    end

    redirect_to redirect, :flash => flash
  end

  def create # add
    authorize! :show, CurriculumUnit.find(params[:id])

    id, tab_name, context_id = params[:id], params[:name], params[:context].to_i # Home, Curriculum_Unit ou outro nao mapeado
    redirect = home_path # se estourou numero de abas, volta para mysolar # Context_General

    # abre abas ate um numero limitado; atualiza como ativa se aba ja existe
    if opened_or_new_tab?(tab_name)
      set_session_opened_tabs(tab_name, {id: id, context: context_id, allocation_tag_id: params[:allocation_tag_id]}, params)
      redirect = home_curriculum_unit_path(id) if context_id == Context_Curriculum_Unit
    end

    redirect_to redirect, flash: flash
  end

  def destroy # close
    tab_name = params[:name]
    set_active_tab_to_home if user_session[:tabs][:active] == tab_name
    user_session[:tabs][:opened].delete(tab_name)

    redirect_to((active_tab[:url][:context] == Context_Curriculum_Unit) ? home_curriculum_unit_path(active_tab[:url][:id]) : home_path, :flash => flash)
  end

  private

    def log_access
      Log.create(log_type: Log::TYPE[:course_access], user_id: current_user.id, curriculum_unit_id: params[:id]) if (params[:context].to_i == Context_Curriculum_Unit)
    end

end