class MessagesController < ApplicationController
  include FilesHelper
  include MessagesHelper
  include SysLog::Actions

  before_filter :prepare_for_group_selection, only: [:index]

  ## [inbox, outbox, trashbox]
  require 'will_paginate/array'
  def index
    allocation_tag_id = active_tab[:url][:allocation_tag_id]
    @show_system_label = allocation_tag_id.nil?

    @box = option_user_box(params[:box])
    @messages = Message.by_box(current_user.id, @box, allocation_tag_id).paginate(page: params[:page] || 1, per_page: Rails.application.config.items_per_page)
    @unreads  = Message.unreads(current_user.id, allocation_tag_id)
  end

  def search
    @box = option_user_box(params[:box])
    @messages = Message.by_box(current_user.id, @box, active_tab[:url][:allocation_tag_id], {}, { user: params[:user], subject: params[:subject] }).paginate(page: params[:page] || 1, per_page: Rails.application.config.items_per_page)

    render partial: 'list'
  end

  def new
    authorize! :index, Message, { on: [@allocation_tag_id  = active_tab[:url][:allocation_tag_id]], accepts_general_profile: true } unless active_tab[:url][:allocation_tag_id].nil?
    @message = Message.new
    @message.files.build
    @unreads = Message.unreads(current_user.id, @allocation_tag_id)
    @reply_to = [User.find(params[:user_id]).to_msg] unless params[:user_id].nil? # se um usuário for passado, colocá-lo na lista de destinatários
    @reply_to = [{resume: t("messages.support")}] unless params[:support].nil?
  end

  def show
    @message = Message.find(params[:id])
    change_message_status(@message.id, "read", @box = params[:box] || "inbox")
  end

  def reply
    @original = Message.find(params[:id])
    raise CanCan::AccessDenied unless @original.user_has_permission?(current_user.id)

    @allocation_tag_id = active_tab[:url][:allocation_tag_id]
    @unreads = Message.unreads(current_user.id, @allocation_tag_id)

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
        @reply_to = @original.users.uniq.map(&:to_msg)
        @message.subject = "#{t(:reply, scope: [:messages, :subject])} #{@message.subject}"
      when "forward"
        # sem contato default
        @message.subject = "#{t(:forward, scope: [:messages, :subject])} #{@message.subject}"
    end
  end

  def create
    @allocation_tag_id = active_tab[:url][:allocation_tag_id]

    # is an answer
    if params[:message][:original].present?
      @original = Message.find(params[:message].delete(:original)) # precisa para a view de new, caso algum problema aconteca
      original_files = @original.files.where(message_files: {id: params[:message].delete(:original_files)})
    end

    begin
      Message.transaction do
        @message = Message.new(message_params, without_validation: true)
        @message.sender = current_user
        @message.allocation_tag_id = @allocation_tag_id

        raise "error" if params[:message][:contacts].empty?
        emails = User.where(id: params[:message][:contacts].split(',')).pluck(:email).flatten.compact.uniq

        @message.files << original_files if original_files and not original_files.empty?
        @message.save!

        Thread.new do
          Notifier.send_mail(emails, @message.subject, new_msg_template, @message.files, current_user.email).deliver
        end
      end

      redirect_to outbox_messages_path, notice: t(:mail_sent, scope: :messages)
    rescue => error
      @unreads = Message.unreads(current_user.id, @allocation_tag_id)
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
     
      flash.now[:alert] = @message.errors.full_messages.join(', ')
      render :new
    end
  end

  ## [read, unread, trash, restore]
  def update
    begin
      Message.transaction do
        params[:id].split(',').map(&:to_i).each { |i| change_message_status(i, params[:new_status], params[:box]) }
      end
      render json: {success: true}
    rescue
      render json: {success: false}, status: :unprocessable_entity
    end
  end

  def count_unread
    render json: { unread: Message.unreads(current_user.id, active_tab[:url][:allocation_tag_id]) }
  end

  def download_files
    file = MessageFile.find(params[:file_id])
    raise CanCan::AccessDenied unless file.message.user_has_permission?(current_user.id)

    download_file(inbox_messages_path, file.attachment.path, file.attachment_file_name)
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
    unless (@allocation_tag_id = params[:allocation_tag_id]).nil?
      allocation_tag = AllocationTag.find(@allocation_tag_id)
      @group         = allocation_tag.group
      @contacts      = User.all_at_allocation_tags(allocation_tag.related, Allocation_Activated, true)
    else
      @contacts = current_user.user_contacts.map(&:user)
    end

    @reply_to = (params[:reply_to].blank? ? [] : User.where(id: params[:reply_to].split(',')).map(&:to_msg))
    render partial: 'contacts'
  end

  private

    def new_msg_template
      system_label = not(@allocation_tag_id.nil?)

      %{
        <b>#{t(:mail_header, scope: :messages)} #{current_user.to_msg[:resume]}</b><br/>
        #{@message.labels(current_user.id, system_label) if system_label}<br/>
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

    def message_params
      params.require(:message).permit(:subject, :content, :contacts, files_attributes: :attachment)
    end

end
