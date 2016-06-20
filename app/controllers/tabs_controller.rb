class TabsController < ApplicationController

  before_filter :clear_breadcrumb_home, only: [:show, :create]
  after_filter :get_group_allocation_tag, only: :create

  def show # activate
    # verifica se a aba que esta sendo acessada esta aberta
    redirect = home_path
    unless user_session[:tabs][:opened].has_key?(params[:id])
      set_active_tab_to_home # o usuário é redirecionado para o Home caso a aba não exista
    else
      set_active_tab(params[:id])
      # dentro da aba, podem existir links abertos
      redirect = active_tab[:breadcrumb].last[:url] if active_tab[:url][:context].to_i == Context_Curriculum_Unit.to_i
    end

    redirect_to redirect, flash: flash
  end

  def create # add
    id, context_id = params[:id], params[:context].to_i # Home, Curriculum_Unit ou outro nao mapeado
    redirect = home_path # se estourou numero de abas, volta para mysolar # Context_General

    # abre abas ate um numero limitado; atualiza como ativa se aba ja existe
    if opened_or_new_tab?(id)
      offer = Offer.find(id)
      params[:name] = offer.allocation_tag.info
      params[:tab] = [offer.curriculum_unit.try(:name) || offer.course.try(:name), offer.semester.name].join(' - ')
      set_session_opened_tabs({ id: id, context: context_id, allocation_tag_id: params[:allocation_tag_id] }, params)
      redirect = home_curriculum_unit_path(id) if context_id == Context_Curriculum_Unit
    end

    redirect_to redirect, flash: flash
  end

  def destroy # close
    tab_id = params[:id]
    set_active_tab_to_home if user_session[:tabs][:active] == tab_id
    user_session[:tabs][:opened].delete(tab_id)

    redirect_to((active_tab[:url][:context] == Context_Curriculum_Unit) ? home_curriculum_unit_path(active_tab[:url][:id]) : home_path, flash: flash)
  end

end
