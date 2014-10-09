require 'ostruct'
include EdxHelper

class UsersController < ApplicationController

  layout false, only: :show
  load_and_authorize_resource only: [:mysolar, :update_photo]

  before_filter :set_active_tab_to_home, only: :profiles
  # before_filter :application_context, only: :mysolar
  after_filter :flash_notice, only: :create

  def show
    # authorize! :show, User, on: allocation_tags # todo usuario vai ter permissao para ver todos?
    @user = User.find(params[:id])
  end

  def verify_cpf

    if (not(params[:cpf].present?) or not(Cpf.new(params[:cpf]).valido?))
      redirect_to login_path(cpf: params[:cpf]), alert: t(:new_user_msg_cpf_error)
    else

      user_cpf   = params[:cpf].delete(".").delete("-")
      integrated = User::MODULO_ACADEMICO["integrated"]
      user       = User.where("translate(cpf,'.-','') = ?", params[:cpf].gsub(/\D/, '')).first

      begin

        if user and integrated # if user exists and system is integrated
          begin
            user_data = User.connect_and_import_user(user_cpf) # try to import
            raise if user_data.nil? # user don't exist at MA
            user.synchronize(user_data) # synchronize user with new MA data
            redirect_to login_path, notice: t("users.notices.ma.use_ma_data").html_safe
          rescue
            redirect_to login_path, alert: t(:new_user_cpf_in_use)
          end
        elsif user and not(integrated) # if user exists and system isn't integrated
          redirect_to login_path, alert: t(:new_user_cpf_in_use)
        else # if user don't exist
          raise if not(integrated)
          user = User.new cpf: user_cpf
          user.connect_and_validates_user unless user.on_blacklist? # try to create user with MA data

          if user.new_record? # doesn't exist at MA
            redirect_to new_user_registration_path(cpf: user_cpf)
          else # user was imported and registered with MA data
            redirect_to login_path, notice: t("users.notices.ma.use_ma_data").html_safe
          end
        end

      rescue
        flash[:warning] = t("users.warnings.ma.cpf_not_verified") if integrated and not(User.new(cpf: user_cpf).on_blacklist?)
        redirect_to new_user_registration_path(cpf: params[:cpf])
      end

    end
  end

  def mysolar
    set_active_tab_to_home

    @user   = current_user
    @offers = Offer.offers_info_from_user(@user)
    @types  = ((not(EDX.nil?) and EDX["integrated"]) ? CurriculumUnitType.all : CurriculumUnitType.where("id <> 7"))
    allocation_tags = @user.activated_allocation_tag_ids(true, true)
    @scheduled_events = Agenda.events(allocation_tags, nil, true) unless allocation_tags.empty?
  end

  def photo
    file_path = User.find(params[:id]).photo.path(params[:style] || :small)
    head(:not_found) and return unless not file_path.nil? and File.exist?(file_path)
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

  # synchronize user data with ma
  def synchronize_ma
    user = params.include?(:id) ? User.find(params[:id]) : current_user
    raise ActiveRecord::RecordNotFound if user.on_blacklist?
    synchronizing_result = user.synchronize
    if synchronizing_result.nil? # user don't exists at MA
      render json: {success: false, message: t("users.warnings.ma.cpf_not_found"), type_message: "warning"}
    elsif synchronizing_result # user synchronized
      render json: {success: true, message: t("users.notices.ma.synchronize"), type_message: "notice", 
        name: user.name, email: user.email, nick: user.nick, username: user.username}
    else # error
      render json: {success: false, alert: t("users.errors.ma.synchronize")}, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: {success: false, message: t("users.warnings.ma.not_possible_syncrhonize"), type_message: "warning"}
  rescue
    render json: {success: false, alert: t("users.errors.ma.synchronize")}, status: :unprocessable_entity
  end

  def profiles
    @allocations = current_user.allocations.where("profile_id != 12").order("profile_id").paginate(page: params[:page])
    respond_to do |format|
      format.html { render layout: false if params[:layout] }
      format.js
    end
  end

  def request_profile
    @allocation = Allocation.new
    @types      = CurriculumUnitType.all
    @profiles   = Profile.where("types <> ? and id <> ?", Profile_Type_Basic, Profile.student_profile).order("name")
    render layout: false
  end

end
