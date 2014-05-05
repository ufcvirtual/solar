require 'active_support/concern'

module SysLog

  module Access
    extend ActiveSupport::Concern
  end

  module Actions
    extend ActiveSupport::Concern

    included do
      after_filter :log_create, only: [:create, :update, :destroy]
    end

    def log_create
      sobj = self.class.to_s.sub("Controller", "").downcase.singularize
      obj = eval("@#{sobj}")

      if obj.respond_to?(:academic_allocations)
        obj.academic_allocations.each do |al|
          LogAction.create(log_type: LogAction::TYPE[request_method(request.request_method)], user_id: current_user.id, created_at: Time.now, tool_id: al.id, ip: request.remote_ip, description: "#{params[sobj.singularize.to_sym]}")
        end
      else # log generico
        description = if params.has_key?(tbname = obj.try(:class).try(:table_name).to_s.singularize.to_sym)
          "#{sobj}: #{obj.id}, #{params[tbname]}"
        elsif params[:id].present?
          "#{sobj}: #{params[:id]}"
        end

        LogAction.create(log_type: LogAction::TYPE[request_method(request.request_method)], user_id: current_user.id, created_at: Time.now, ip: request.remote_ip, description: description)
      end
    rescue => error
      # do nothing
    end

    private

      def request_method(rm)
        case rm
          when "POST"
            :create
          when "PUT", "PATCH"
            :update
          when "DELETE"
            :destroy
        end
      end

  end # Actions

  module Devise
    extend ActiveSupport::Concern

    included do
      # request reset (create/reset_password_user) and  actually reset (update) user password
      after_filter :log_update, only: [:update]
      after_filter :log_request, only: [:create, :reset_password_user]
    end

    def log_update
      unless not(params[:user].include?(:password)) or params[:user][:password].blank? or params[:user][:password] != params[:user][:password_confirmation]
        user = (current_user.nil? ? (params[:user].include?(:id) ? User.find(params[:id]) : User.find_by_reset_password_token(params[:user][:reset_password_token])) : current_user)
        LogAction.update(user_id: user.id, ip: request.remote_ip, description: "user: #{user.id}, password", created_at: Time.now) unless user.nil?
      end
    rescue
      # do nothing
    end

    def log_request
      user_email = params.include?(:user) ? User.find_by_email(params[:user][:email]) : User.find(params[:id])
      user       = (current_user.nil? ?  user_email : current_user)
      LogAction.request_password(user_id: user.id, ip: request.remote_ip, description: "user: #{user_email.id}, {email: #{user_email.email}}", created_at: Time.now) unless user.nil?
    rescue
      # do nothing
    end

  end

end
