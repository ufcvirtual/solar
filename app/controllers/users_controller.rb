require 'ostruct'

class UsersController < ApplicationController

  load_and_authorize_resource :except => [:photo, :edit_photo, :fb_authentication]

  def mysolar
    set_active_tab_to_home

    @user = current_user
    allocation_tags = @user.allocation_tags.where(allocations: {status: Allocation_Activated.to_i}).compact.uniq.map(&:related).flatten.uniq.sort

    ## Portlet do calendario; destacando dias que possuem eventos
    unless allocation_tags.empty?
      schedules_events = Schedule.events(allocation_tags)
      schedules_events_dates = schedules_events.collect do |schedule_event|
        schedule_end_date = schedule_event['end_date'].nil? ? "" : schedule_event['end_date'].to_date.to_s()
        [schedule_event['start_date'].to_date.to_s(), schedule_end_date]
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
    # breadcrumb = active_tab[:breadcrumb].last
    # redirect = breadcrumb.nil? ? home_path : breadcrumb[:url]
    respond_to do |format|
      begin
        raise t(:user_error_no_file_sent) unless params.include?(:user) && params[:user].include?(:photo)
        @user.update_attributes!(params[:user])
        format.html { redirect_to :back, notice: t(:successful_update_photo) }
      rescue Exception => error
        error_msg = ''
        if error.message.index("not recognized by the 'identify'") # erro que nao teve tratamento
          error_msg = error.message
          # error_msg = [t(:photo_content_type, scope: [:activerecord, :attributes, :user]),
          #              t(:invalid_type, scope: [:activerecord, :errors, :models, :user, :attributes, :photo_content_type])].compact.join(' ')
        else # exibicao de erros conhecidos
          error_msg << error.message
        end
        format.html { redirect_to :back, alert: error_msg }
      end
    end
  end
end

