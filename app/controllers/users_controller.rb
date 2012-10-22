class UsersController < ApplicationController

  load_and_authorize_resource :except => [:photo, :edit_photo]

  def mysolar
    set_active_tab_to_home

    @user           = current_user
    allocation_tags = @user.allocations.where(status: Allocation_Activated).map(&:allocation_tag).compact.map(&:related).flatten.uniq.sort

    ## Portlet do calendario; destacando dias que possuem eventos
    unless allocation_tags.empty?
      schedules_events       = Schedule.all_by_allocation_tags(allocation_tags)
      schedules_events_dates = schedules_events.collect do |schedule_event|
        [schedule_event['start_date'].to_date.to_s(), schedule_event['end_date'].to_date.to_s()]
      end
      @scheduled_events = schedules_events_dates.flatten.uniq
    end
  end

  def photo
    file_path = User.find(params[:id]).photo.path(params[:style] || :small)
    head(:bad_request) and return unless not file_path.nil? and File.exist?(file_path)
    send_file(file_path, { :disposition => 'inline', :content_type => 'image' })
  end

  def edit_photo
    render :layout => false
  end

  def update_photo
    breadcrumb = active_tab[:breadcrumb].last
    redirect = breadcrumb.nil? ? {:controller => :home} : breadcrumb[:url]

    respond_to do |format|
      begin
        raise t(:user_error_no_file_sent) unless params.include?(:user) && params[:user].include?(:photo)
        @user.update_attributes!(params[:user])
        flash[:notice] = t(:successful_update_photo)
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

        flash[:alert] = error_msg
        format.html { redirect_to(redirect) }
      end
    end
  end
end
