class MessagesController < ApplicationController
  include FilesHelper
  include MessagesHelper
  include SysLog::Actions
 
  before_action :doorkeeper_authorize!, only: [:api_download]
  before_action :prepare_for_group_selection, only: [:index]

  ## [inbox, outbox, trashbox]
  def index
    allocation_tag_id = active_tab[:url][:allocation_tag_id]

    @show_system_label = allocation_tag_id.nil?

    @box = option_user_box(params[:box])
    @page = (params[:page] || 1).to_i

    search = {}
    search.merge!({user: params[:user]}) unless params[:user].blank?
    search.merge!({subject: params[:subject]}) unless params[:subject].blank?

    options = {page: @page, ignore_at: true}
    options.merge!(option_search_for(params[:search_for]))

    @messages = Message.by_box(current_user.id, @box, allocation_tag_id, options, search)
    @message_ids =  Message.by_box(current_user.id, @box, allocation_tag_id, options, search, 100, 0).map{|m|m.id}

    @limit = Rails.application.config.items_per_page
    @min = (@page * @limit) - @limit

    @unreads = @messages.first.try(:unread) rescue 0
    if @unreads.nil?
      @unreads = Message.get_count_unread_in_inbox(current_user.id, allocation_tag_id, options.except(:ignore_at), search)
    end
    render partial: 'list' unless params[:page].nil?
  end

  def pending
    # used at the uc home
    @page = (params[:page] || 1).to_i

    @messages = Message.by_box(current_user.id, 'inbox', active_tab[:url][:allocation_tag_id], { only_unread: true, page: @page, ignore_at: true })

    @limit = Rails.application.config.items_per_page
    @min = (@page * @limit) - @limit
    @total = @messages.try(:first).total_messages rescue 0

    respond_to do |format|
      format.json { render json: @messages }
      format.js
    end
  end

  def search
    @box = option_user_box(params[:box])
    @page = (params[:page] || 1).to_i

    options = {page: @page, ignore_at: true}
    options.merge!(option_search_for(params[:search_for]))

    @messages = Message.by_box(current_user.id, @box, active_tab[:url][:allocation_tag_id], options, { user: params[:user], subject: params[:subject] })
    @message_ids = Message.by_box(current_user.id, @box, active_tab[:url][:allocation_tag_id], options, { user: params[:user], subject: params[:subject] }, 100, 0).map{|m|m.id}

    @limit = Rails.application.config.items_per_page
    @min = (@page * @limit) - @limit

    render partial: 'list'
  end

  def new
    authorize! :index, Message, { on: [@allocation_tag_id  = active_tab[:url][:allocation_tag_id]], accepts_general_profile: true } unless active_tab[:url][:allocation_tag_id].nil?
    @message = Message.new
    @message.files.build

    at = AllocationTag.find(@allocation_tag_id) rescue nil

    @reply_to = [User.find(params[:user_id]).to_msg] unless params[:user_id].nil? # se um usuário for passado, colocá-lo na lista de destinatários
    @reply_to = [{resume: t("messages.support")}] unless params[:support].nil?

    if params[:support_help]
      ac = Webconference.set_status_support_help(params[:ac], Support_Help_Message) # Muda o status da AC para Support_Help_Message
      web = Webconference.find(ac.academic_tool_id)
      @reply_to = [{resume: t("messages.support_help"), subject: web.title + ' - ' + l(web.initial_time, format: :mask_with_time_form) + ' - ' + at.try(:info)}] # Envia o destinatário e o assunto para a mensagem
    end

    @support = params[:support]

    @scores = params[:scores]

    # if @support || params[:layout] || params[:support_help]
    if params[:support_help]
      flash.now[:warning] = t('messages.support_warning')
    elsif !(@support || params[:layout])
      render layout: false
    end

  end

  def show
    @message = Message.find(params[:id])
    @message_ids = params[:ids]

    unless @message_ids.nil?
      ids = @message_ids.to_a.split(params[:id])
      @next_message_id = ids[0].empty? ? nil : ids[0].last
      @previous_message_id = ids[1].empty? ? nil : ids[1].shift
    end

    sent_by_responsible = @message.allocation_tag.is_responsible?(@message.sent_by.id) unless @message.allocation_tag_id.blank?
    LogAction.create(log_type: LogAction::TYPE[:update], user_id: current_user.id, ip: get_remote_ip, description: "message: #{@message.id} read message from #{sent_by_responsible ? 'responsible' : 'other'}", allocation_tag_id: @message.allocation_tag_id) rescue nil
    change_message_status(@message.id, "read", @box = params[:box] || "inbox")
  end

  def reply
    @original = Message.find(params[:id])
    raise CanCan::AccessDenied unless @original.user_has_permission?(current_user.id)

    @allocation_tag_id = active_tab[:url][:allocation_tag_id]

    @message = Message.new subject: @original.subject
    @message.files.build

    @message.content = reply_msg_template

    unless @allocation_tag_id.nil?
      allocation_tag      = AllocationTag.find(@allocation_tag_id)
      @group              = allocation_tag.group
      @contacts           = User.all_at_allocation_tags(allocation_tag.related, Allocation_Activated, true)
    else
      @contacts = current_user.user_contacts.map(&:user)
    end

    @files = @original.files

    @reply_to = []
    case params[:type]
      when "reply"
        @reply_to = [@original.sent_by.to_msg]
        @message.subject = "#{t(:reply, scope: [:messages, :subject])} #{@message.subject}"
      when "reply_all"
        @reply_to = @original.users.distinct.map(&:to_msg)
        @message.subject = "#{t(:reply, scope: [:messages, :subject])} #{@message.subject}"
      when "forward"
        # sem contato default
        @message.subject = "#{t(:forward, scope: [:messages, :subject])} #{@message.subject}"
    end
  end

  def create
    @allocation_tag_id = params[:allocation_tag_id].blank? ? active_tab[:url][:allocation_tag_id] : params[:allocation_tag_id]

    # is an answer
    if params[:message][:original].present?
      @original = Message.find(params[:message].delete(:original)) # precisa para a view de new, caso algum problema aconteca
      original_files = @original.files.where(message_files: {id: params[:message].delete(:original_files)})
    end

    begin
      Message.transaction do
        #@message = Message.new(message_params, without_validation: true)
        @message = Message.new(message_params)
        @message.sender = current_user
        @message.allocation_tag_id = @allocation_tag_id

        raise "error" if params[:message][:contacts].nil? && params[:message][:support].blank?
        emails = []
        unless params[:message][:contacts].nil?
          emails = User.joins('LEFT JOIN personal_configurations AS nmail ON users.id = nmail.user_id')
                        .where("(nmail.message IS NULL OR nmail.message=TRUE)")
                        .where(id: params[:message][:contacts].split(',')).pluck(:email).flatten.compact.uniq
        end

        emails << params[:message][:support] unless params[:message][:support].blank?
        p emails

        #@message.files << original_files.dup if original_files and not original_files.empty?
        @message.save!
        if original_files and not original_files.empty?
          original_files.each do |file|
            new_file = file.dup
            new_file.message_id = @message.id
            new_file.attachment = file.attachment
            new_file.save!
          end
        end

        Job.send_mass_email(emails, @message.subject, new_msg_template, @message.files.to_a, current_user.email)
        #Notifier.send_mail(emails, @message.subject, new_msg_template, @message.files.to_a, current_user.email).deliver
      end
      

      if params[:scores]=='true'
        redirect_back(fallback_location: solar_home_path)
      else
        respond_to do |format|
          format.html { redirect_to outbox_messages_path, notice: t(:mail_sent, scope: :messages) }
          #format.json { render :json => {"msg": "Contato removido com sucesso"} }
        end
      end
    rescue ActiveRecord::RecordInvalid
      @message.errors.each do |attribute, erro|
        @attribute = attribute
      end
      @support = params[:message][:support]
      @reply_to = [{resume: t("messages.support")}] unless params[:message][:support].nil?
      
      render :new
    rescue => error
      if params[:scores]=='true'
        render json: { success: false, alert: @message.errors.full_messages.join(', ') }, status: :unprocessable_entity
      else
        p error
        unless @allocation_tag_id.nil?
          allocation_tag      = AllocationTag.find(@allocation_tag_id)
          @group              = allocation_tag.group
          @contacts           = User.all_at_allocation_tags(RelatedTaggable.related(group_id: @group.id), Allocation_Activated, true)
        else
          @contacts = current_user.user_contacts.map(&:user)
        end
        @message.files.build

        @message.errors.each do |attribute, erro|
          @attribute = attribute
        end
        @reply_to = []
        @reply_to = User.where(id: params[:message][:contacts].split(',')).select("id, (name||' <'||email||'>') as resume")
        @support = params[:support]

        flash.now[:alert] = @message.errors.full_messages.join(', ')
        render :new
      end
    end
  end

  ## [read, unread, trash, restore]
  def update
    begin
      Message.transaction do
        params[:id].split(',').map(&:to_i).each { |i| change_message_status(i, params[:new_status], option_user_box(params[:box])) }
      end
      render json: {success: true}
    rescue => error
      render json: {success: false}, status: :unprocessable_entity
    end
  end

  def count_unread
    render json: { unread: (Message.by_box(current_user.id, 'inbox', active_tab[:url][:allocation_tag_id], {ignore_at: true, page: 1, only_unread: true}).first.try(:total_messages) rescue 0) }
  end

  def download_files
    file = MessageFile.find(params[:file_id])
    raise CanCan::AccessDenied unless file.message.user_has_permission?(current_user.id)

    download_file(inbox_messages_path, file.attachment.path, file.attachment_file_name)
  end

  def api_download
    api_guard_with_access_token_or_authenticate
    file = MessageFile.find(params[:file_id])

    raise CanCan::AccessDenied unless file.message.user_has_permission?(current_user.id)

    begin
      download_file(nil, file.attachment.path, file.attachment_file_name)
    rescue
      raise 'file not found'
    end
  rescue ActiveRecord::RecordNotFound => error
    Rails.logger.info "[API] [ERROR] [#{Time.now}] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [404] message: #{error}"
    render json: {success: false, status: :not_found, error: error}
  rescue => error
    Rails.logger.info "[API] [ERROR] [#{Time.now}] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [404] message: #{error}"
    render json: {success: false, status: :unprocessable_entity, error: error}
  end

  def find_users
    @allocation_tags_ids = AllocationTag.get_by_params(params, related = true)[:allocation_tags]

    raise CanCan::AccessDenied if current_user.is_researcher?(@allocation_tags_ids)
    authorize! :show, CurriculumUnit, { on: @allocation_tags_ids, read: true }

    @users = User.all_at_allocation_tags(@allocation_tags_ids, Allocation_Activated, true)
    @allocation_tags_ids = @allocation_tags_ids.join('_')
    render partial: 'users'
  rescue => error
    render json: { success: false, alert: t('messages.errors.permission') }, status: :unprocessable_entity
  end

  def contacts
    @content_student = false
    @content_responsibles = false
    unless (@allocation_tag_id = params[:allocation_tag_id]).nil?
      allocation_tag = AllocationTag.find(@allocation_tag_id)
      @group         = allocation_tag.group
    # else
    #   @contacts = current_user.user_contacts.map(&:user)
    end
    @contacts = User.all_at_allocation_tags(allocation_tag.try(:related), Allocation_Activated, true)

    @reply_to = (params[:reply_to].blank? ? [] : User.where(id: params[:reply_to].split(',')).map(&:to_msg))

    unless params[:reply_to].blank? || @contacts.blank?
      @list = @contacts.where('users.id IN (?) ', params[:reply_to].split(','))
      @content_student = @list.any? { |u| u.types.to_i==Profile_Type_Student }
      @content_responsibles = @list.any? { |u| u.types.to_i==Profile_Type_Class_Responsible }
    end

    render partial: 'contacts'
  end

  def new_score_message_user
    authorize! :index, Message, { on: [@allocation_tag_id  = active_tab[:url][:allocation_tag_id]], accepts_general_profile: true }
    @message = Message.new
    @message.files.build
    unless params[:user_ids].nil?
      users = User.find(params[:user_ids].split(","))
      @reply_to_many = users.size > 0 ? users.map{|u| u.to_msg} : nil

      @reply_to = [User.find(params[:user_ids]).to_msg]
    end
    @scores = true
    render partial: 'form'
  end

  private

    def new_msg_template
      system_label = not(@allocation_tag_id.nil?)
      info = @message.labels(current_user.id, system_label).to_s.delete('[]"') if system_label

      %{
        <b>#{t(:mail_header, scope: :messages)} #{current_user.to_msg[:resume]}</b><br/>
        #{info}<br/>
        ________________________________________________________________________<br/><br/>
        #{@message.content}
      }
    end

    def reply_msg_template
      %{
        <br/><br/>----------------------------------------<br/>
        #{t(:from, scope: [:messages, :show])} #{@original.sent_by.to_msg[:resume]}<br/>
        #{t(:date, scope: [:messages, :show])} #{l(@original.created_at, format: :clock)}<br/>
        #{t(:subject, scope: [:messages, :show])} #{@original.subject}<br/>
        #{t(:to, scope: [:messages, :show])} #{@original.users.map(&:to_msg).map{ |c| c[:resume] }.join(',')}<br/>
        #{@original.content}
      }
    end

    def option_user_box(type)
      return type if ['outbox', 'trashbox'].include?(type)
      'inbox'
    end

    def option_search_for(type)
      return {type.to_sym => true} if ['only_read', 'only_unread'].include?(type)
      {}
    end

    def message_params
      params.require(:message).permit(:subject, :content, :contacts, :support, files_attributes: :attachment)
    end

end
