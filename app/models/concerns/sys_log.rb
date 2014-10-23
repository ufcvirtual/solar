require 'active_support/concern'

module SysLog

  module Access
    extend ActiveSupport::Concern
  end

  module Actions
    extend ActiveSupport::Concern

    included do
      after_filter :log_create, unless: Proc.new {|c| request.get? }, except: :evaluate
    end

    def log_create
      model = self.class.to_s.sub("Controller", "")
      sobj  = model.tableize
      objs  = eval("@#{sobj}") # created/updated/destroyied objects could be a list
      sobj  = sobj.singularize
      obj   = eval("@#{sobj}")
      objs  = [eval("@#{sobj}")].compact unless obj.nil? # only if obj doesn't exist, use objs list

      # if some error happened, don't save log
      response_status = JSON.parse(response.body) rescue nil
      return if ((not(response_status.nil?) and response_status.has_key?("success") and response_status["success"] == false) or (params.include?(:success) and params[:success] == false))

      if not(objs.nil?) and not(objs.empty?)
        objs.each do |obj|
          description = "#{sobj.singularize}: #{obj.id}, #{ActiveSupport::JSON.encode(obj.attributes.except('attachment_updated_at', 'updated_at', 'created_at'))}" rescue nil
          if obj.respond_to?(:academic_allocations) and not obj.academic_allocations.empty?
            allocation_tag_id = params[:allocation_tag_id] || active_tab[:url][:allocation_tag_id] || obj.allocation_tag.id rescue nil
            obj.academic_allocations.each do |al|
              LogAction.create(log_type: LogAction::TYPE[request_method(request.request_method)], user_id: current_user.id, academic_allocation_id: al.id, allocation_tag_id: allocation_tag_id, ip: request.remote_ip, description: description)
            end
          else # generic log
            generic_log(sobj, obj)
          end
        end
      else
        generic_log(sobj)
      end

    rescue
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

      def generic_log(sobj, obj = nil)
        return if not(obj.nil?) and obj.new_record? # not saved

        academic_allocation_id = nil
        tbname = obj.try(:class).try(:table_name).to_s.singularize.to_sym if obj.try(:class).respond_to?(:table_name)
        description = if not(tbname.nil?) and params.has_key?(tbname) and not(obj.nil?)

          obj_attrs = obj.attributes.except('attachment_updated_at', 'created_at', 'updated_at')
          obj_attrs.merge!({'files' => obj.files.map {|f| f.attributes.except('attachment_updated_at') } }) if obj.respond_to?(:files) and obj.files.any?
          obj_attrs = ActiveSupport::JSON.encode(obj_attrs)

          "#{sobj}: #{obj.id}, #{obj_attrs}"
        elsif params[:id].present?
          # gets any extra information if exists
          info = ActiveSupport::JSON.encode(params.except(:controller, :action, :id))
          "#{sobj}: #{[params[:id], info].compact.join(", ")}"
        else # controllers saving other objects. ex: assingments -> student files
          d = []
          variables = self.instance_variable_names.to_ary.delete_if { |v| v.to_s.start_with?("@_") or ["@current_user", "@current_ability"].include?(v) }
          variables.each do |v|
            o = eval(v)
            academic_allocation_id = o.academic_allocation.id if o.respond_to?(:academic_allocation) # assignment_file
            d << %{#{v.sub("@", "")}: #{o.as_json}} unless ["Array", "String"].include?(o.class)
          end
          d.join(", ")
        end

        LogAction.create(log_type: LogAction::TYPE[request_method(request.request_method)], user_id: current_user.id, ip: request.remote_ip, academic_allocation_id: academic_allocation_id, description: description) unless description.nil?
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
        LogAction.updating(user_id: user.id, ip: request.remote_ip, description: "user: #{user.id}, password", created_at: Time.now) unless user.nil?
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
