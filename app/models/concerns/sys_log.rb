require 'active_support/concern'

module SysLog

  module Access
    extend ActiveSupport::Concern
  end

  module Actions
    extend ActiveSupport::Concern

    included do
      after_filter :log_create, unless: Proc.new {|c| request.get? }, except: [:evaluate, :change_participant, :import, :export, :annul, :remove_record]
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

      return if ((!(response_status.nil?) && response_status.has_key?("success") && response_status["success"] == false) || (params.include?(:success) && params[:success] == false))

      if !(objs.nil?) && !(objs.empty?)
        objs.each do |obj|
          description = obj.respond_to?(:log_description) ? obj.log_description : "#{sobj.singularize}: #{obj.id}, #{ActiveSupport::JSON.encode(obj.attributes.except('attachment_updated_at', 'updated_at', 'created_at', 'id'))}" rescue nil
          if ((obj.respond_to?(:academic_allocations) && !obj.try(:academic_allocations).empty?) || obj.respond_to?(:academic_allocation))
            allocation_tag_id = params[:allocation_tag_id] || active_tab[:url][:allocation_tag_id] || obj.allocation_tag.id rescue nil
            [(obj.respond_to?(:academic_allocations) ? obj.academic_allocations : obj.academic_allocation)].flatten.each do |al|
              LogAction.create(log_type: LogAction::TYPE[request_method(request.request_method)], user_id: current_user.id, academic_allocation_id: al.id, allocation_tag_id: allocation_tag_id, ip: get_remote_ip, description: description)
            end
          elsif (obj.respond_to?(:allocation_tag) && !(obj.allocation_tag.nil?))
            LogAction.create(log_type: LogAction::TYPE[request_method(request.request_method)], user_id: current_user.id, allocation_tag_id: obj.allocation_tag.id, ip: get_remote_ip, description: description)
          else # generic log
            generic_log(sobj, obj)
          end
        end
      else
        generic_log(sobj)
      end

    rescue => error
      # do nothing
    end

    private

      def request_method(rm)
        case rm
          when 'POST'
            :create
          when 'PUT', 'PATCH'
            :update
          when 'DELETE'
            :destroy
        end
      end

      def generic_log(sobj, obj = nil)
        return if params.include?(:digital_classes)
        return if !obj.nil? && obj.new_record?# && !params.include?(:digital_classes) # not saved

        # academic_allocation_id = obj.try(:academic_allocation).try(:id)
        academic_allocation_id = nil
        tbname = obj.try(:class).try(:table_name).to_s.singularize.to_sym if obj.try(:class).respond_to?(:table_name)
        description = if !tbname.nil? && (params.has_key?(tbname) || params.size <= 3) && !obj.nil?

          obj_attrs = (obj.respond_to?(:log_description) ? obj.log_description : obj.attributes.except('attachment_updated_at', 'created_at', 'updated_at'))
          obj_attrs.merge!({'files' => obj.files.map {|f| f.attributes.except('attachment_updated_at') } }) if obj.respond_to?(:files) && obj.files.any?
          obj_attrs = ActiveSupport::JSON.encode(obj_attrs)

          "#{sobj}: #{obj.id}, changed: #{obj.changed}, #{obj_attrs}"
        elsif params[:id].present?
          # gets any extra information if exists
          info = ActiveSupport::JSON.encode(params.except(:controller, :action, :id))
          "#{sobj}: #{[params[:id], info].compact.join(", ")}"
        else # controllers saving other objects. ex: assingments -> student files
          d = []
          variables = self.instance_variable_names.to_ary.delete_if { |v| v.to_s.start_with?("@_") || ["@current_user", "@current_ability"].include?(v) }
          variables.each do |v|
            o = eval(v)
            academic_allocation_id = o.academic_allocation.id if o.respond_to?(:academic_allocation) # assignment_file
            d << %{#{v.sub("@", "")}: #{o.as_json}} unless ["Array", "String"].include?(o.class)
          end
          d.join(', ')
          d = "#{params[:controller]}: #{params.except('controller').to_s}" if d.blank?
        end

        LogAction.create(log_type: LogAction::TYPE[request_method(request.request_method)], user_id: current_user.id, ip: get_remote_ip, academic_allocation_id: academic_allocation_id, description: description) unless description.nil?
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
      unless !(params[:user].include?(:password)) || params[:user][:password].blank? || params[:user][:password] != params[:user][:password_confirmation]
        user = (current_user.nil? ? (params[:user].include?(:id) ? User.find(params[:id]) : User.find_by_reset_password_token(params[:user][:reset_password_token])) : current_user)
        LogAction.updating(user_id: user.id, ip: get_remote_ip, description: "user: #{user.id}, password", created_at: Time.now) unless user.nil?
      end
    rescue
      # do nothing
    end

    def log_request
      user_email = params.include?(:user) ? User.find_by_email(params[:user][:email]) : User.find(params[:id])
      user       = (current_user.nil? ?  user_email : current_user)
      LogAction.request_password(user_id: user.id, ip: get_remote_ip, description: "user: #{user_email.id}, {email: #{user_email.email}}", created_at: Time.now) unless user.nil?
    rescue
      # do nothing
    end

  end

end
