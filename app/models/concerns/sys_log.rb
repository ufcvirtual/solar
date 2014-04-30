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
      else

        description = if params.has_key?(obj.class.table_name.singularize.to_sym) # criacao de post
          "#{sobj}: #{obj.id}, #{params[obj.class.table_name.singularize.to_sym]}"
        elsif params[:id].present?
          "#{sobj}: #{params[:id]}"
        end

        LogAction.create(log_type: LogAction::TYPE[request_method(request.request_method)], user_id: current_user.id, created_at: Time.now, ip: request.remote_ip, description: description)
      end
    rescue => error
      raise "reitrar? #{error}"
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

end
