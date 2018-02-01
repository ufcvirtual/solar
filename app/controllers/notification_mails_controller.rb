class NotificationMailsController < ApplicationController

  include SysLog::Actions
  layout false, except: [:index]

  def update
    user = current_user
    @notification_mail = NotificationMail.find(params[:id])

    if @notification_mail.update_attributes(notification_mails_params)
      render json: {success: true, notice: t('users.configure.success.updated')}
    else
      render json: {success: false, notice: t('users.configure.error.updated')}
    end
  rescue => error
    request.format = :json
    raise error.class
  end


  private

    def notification_mails_params
      params.require(:notification_mail).permit(:message, :post, :exam)
    end 
end
