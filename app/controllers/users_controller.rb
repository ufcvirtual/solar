class UsersController < ApplicationController

  include ApplicationHelper

  load_and_authorize_resource

  # GET /users
  def index
    render :action => :mysolar
  end

  # GET /users/1/edit
  def edit
    # utilizando devise
    set_active_tab_to_home
    render :action => :mysolar
    #    redirect_to :action => "edit", :controller => "devise/registrations"
  end

  ##############################
  #     PORTLETS DO USUARIO    #
  ##############################

  def mysolar

    set_active_tab_to_home
    @user = current_user

    ######
    # Portlet do calendario
    # destacando dias que possuem eventos
    ######
    c_units = CurriculumUnit.find_default_by_user_id(current_user.id)
    allocation_tags = c_units.collect { |unit|
      unit['allocation_tag_id'].to_i
    }
    schedules_events = Schedule.all_by_allocation_tags(allocation_tags)
    schedules_events_dates = schedules_events.collect { |schedule_event|
      [schedule_event['start_date'], schedule_event['end_date']]
    }

    @scheduled_events = schedules_events_dates.flatten.uniq
  end

  ##################################
  # modificacao da foto do usuario #
  ##################################

  def update_photo

    breadcrumb = active_tab[:breadcrumb].last
    redirect = breadcrumb.nil? ? {:controller => :home} : breadcrumb[:url]

    respond_to do |format|
      begin

        # verifica se o arquivo foi adicionado
        raise t(:error_no_file_sent) unless params.include?(:user) && params[:user].include?(:photo)

        @user.update_attributes!(params[:user])

        flash[:success] = t(:successful_update_photo)
        format.html { redirect_to(redirect) }

      rescue Exception => error

        error_msg = ''
        if error.message.index("not recognized by the 'identify'") # erro que nao teve tratamento
          # se aparecer outro erro nao exibe o erro de arquivo nao identificado
          error_msg << t(:activerecord)[:attributes][:user][:photo_content_type] + " "
          error_msg << t(:activerecord)[:errors][:models][:user][:attributes][:photo_content_type][:invalid_type] + "<br />"
        else # exibicao de erros conhecidos
          error_msg << error.message
        end

        flash[:error] = error_msg
        format.html { redirect_to(redirect) }
      end
    end

  end

end
