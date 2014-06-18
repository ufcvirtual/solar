class AssignmentsController < ApplicationController

  include SysLog::Actions
  include AssignmentsHelper
  include FilesHelper

  before_filter :prepare_for_group_selection, :only => [:professor, :student_view]
  before_filter Proc.new { |c| @allocation_tag = AllocationTag.find(active_tab[:url][:allocation_tag_id]) }, only: [:download_public_files, :download_files]

  load_and_authorize_resource :only => [:import_groups_page, :import_groups, :manage_groups, :send_comment, :remove_comment] #, :evaluate
  authorize_resource :only => [:download_files, :upload_file, :send_public_files_page, :delete_file]

  layout false, only: [:index, :new, :edit, :create, :update, :destroy, :show]

  def index
    @allocation_tags_ids = ( params.include?(:groups_by_offer_id) ? Offer.find(params[:groups_by_offer_id]).groups.map(&:allocation_tag).map(&:id) : params[:allocation_tags_ids] )
    authorize! :list, Assignment, on: @allocation_tags_ids

    @assignments = Assignment.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).order("name").uniq
  end

  def new
    authorize! :create, Assignment, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @assignment = Assignment.new
    @assignment.build_schedule(start_date: Date.current, end_date: Date.current)
    @assignment.enunciation_files.build

    @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids.split(" ")].flatten}).map(&:code).uniq
  end

  def edit
    authorize! :update, Assignment, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @assignment = Assignment.find(params[:id])
    @assignment.enunciation_files.build if @assignment.enunciation_files.empty?

    @enunciation_files = @assignment.enunciation_files.compact
    @schedule     = @assignment.schedule
    @groups_codes = @assignment.groups.map(&:code)
  end

  def create
    authorize! :create, Assignment, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten

    @assignment = Assignment.new params[:assignment]

    begin
      Assignment.transaction do
        @assignment.save!
        @assignment.academic_allocations.create @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
      end

      render json: {success: true, notice: t(:created, scope: [:assignments, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue => error
      @error = error.to_s.start_with?("academic_allocation") ? error.to_s.gsub("academic_allocation", "") : nil

      @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:code).uniq
      @assignment.enunciation_files.build if @assignment.enunciation_files.empty?
      @allocation_tags_ids = @allocation_tags_ids.join(" ")

      render :new
    end
  end

  def update
    @assignment = Assignment.find(params[:id])
    authorize! :update, Assignment, on: @allocation_tags_ids = params[:allocation_tags_ids]

    begin
      @assignment.update_attributes!(params[:assignment])

      render json: {success: true, notice: t(:updated, scope: [:assignments, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue
      @groups_codes = @assignment.groups.map(&:code)
      @assignment.enunciation_files.build if @assignment.enunciation_files.empty?

      render :edit
    end
  end

  def destroy
    authorize! :destroy, Assignment, on: @allocation_tags_ids = params[:allocation_tags_ids]

    begin
      Assignment.transaction do
        assignments = Assignment.includes(:sent_assignments).where(id: params[:id].split(",").flatten, sent_assignments: {id: nil})
        raise "error" if assignments.empty?

        Assignment.transaction do
          assignments.destroy_all
        end
      end
      render json: {success: true, notice: t(:deleted, scope: [:assignments, :success])}
    rescue
      render json: {success: false, alert: t(:deleted, scope: [:assignments, :error])}, status: :unprocessable_entity
    end
  end

  def show
    authorize! :show, Assignment, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @assignment = Assignment.find(params[:id])
    @enunciation_files = @assignment.enunciation_files.compact
    @groups_codes = @assignment.groups.map(&:code)
  end

  # Não REST

  ##
  # Informações do andamento da atividade para um aluno/grupo escolhido
  # Nesta página, há as opções de comentários para o trabalho do aluno/grupo, avaliação e afins
  # => responsáveis: podem comentar/avaliar
  # => alunos: podem enviar/excluir arquivos
  ##
  def student
    @allocation_tag = AllocationTag.find(active_tab[:url][:allocation_tag_id])
    authorize! :student, Assignment, on: [@allocation_tag.id]

    @assignment      = Assignment.find(params[:id])
    @user            = current_user
    @student_id      = params[:group_id].nil? ? params[:student_id] : nil
    @group_id        = params[:group_id].nil? ? nil : params[:group_id] 
    @group           = GroupAssignment.find(params[:group_id]) unless @group_id.nil? # grupo
    @sent_assignment = @assignment.sent_assignment_by_user_id_or_group_assignment_id(@allocation_tag.id, @student_id, @group_id)
    @situation       = @assignment.situation_of_student(@allocation_tag.id, @student_id, @group_id)
    @assignment_enunciation_files = AssignmentEnunciationFile.find_all_by_assignment_id(@assignment.id)  # arquivos que fazem parte da descrição da atividade

    raise CanCan::AccessDenied unless @assignment.user_can_access_assignment?(@allocation_tag, current_user.id, @student_id, @group_id)

    unless @sent_assignment.nil?
      @sent_assignment_files = @sent_assignment.assignment_files
      @comments              = @sent_assignment.assignment_comments
    end
  end

  def professor
    allocation_tags_ids = params[:allocation_tags_ids] || [active_tab[:url][:allocation_tag_id]]
    authorize! :professor, Assignment, on: allocation_tags_ids

    @individual_activities = Assignment.joins(:academic_allocations, :schedule).where(type_assignment: Assignment_Type_Individual,  academic_allocations: {allocation_tag_id:  allocation_tags_ids}).order(:start_date)
    @group_activities      = Assignment.joins(:academic_allocations, :schedule).where(type_assignment: Assignment_Type_Group,       academic_allocations: {allocation_tag_id:  allocation_tags_ids}).order(:start_date)

    render :layout => false if params[:allocation_tags_ids]
  end

  def student_view
    authorize! :student_view, Assignment

    group_id                     = params['selected_group'] # turma
    @student_id                  = current_user.id
    @individual_assignments_info = Assignment.student_assignments_info(group_id, @student_id, Assignment_Type_Individual) # atividades individuais pelo grupo_id em que o usuario esta inserido
    @group_assignments_info      = Assignment.student_assignments_info(group_id, @student_id, Assignment_Type_Group) # atividades em grupo pelo grupo_id em que o usuario esta inserido
    @public_area                 = PublicFile.all_by_class_id_and_user_id(group_id, @student_id)
  end

  ##
  # Informações da atividade individual escolhida na listagem com a lista de alunos daquela turma
  # Informações da atividade em grupo escolhida na listagem com a lista dos grupos daquela turma, permitindo seu gerenciamento
  ##
  def information
    @assignment = Assignment.find(params[:id])
    authorize! :information, @assignment

    @assignment_enunciation_files = AssignmentEnunciationFile.find_all_by_assignment_id(@assignment.id)  #arquivos que fazem parte da descrição da atividade
    @allocation_tag = AllocationTag.find(active_tab[:url][:allocation_tag_id])
    if @assignment.type_assignment == Assignment_Type_Group
      academic_allocation     = AcademicAllocation.find_by_allocation_tag_id_and_academic_tool_id_and_academic_tool_type(@allocation_tag.id, @assignment.id, 'Assignment')
      @groups                 = GroupAssignment.find_all_by_academic_allocation_id(academic_allocation)
      @students_without_group = @assignment.students_without_groups(@allocation_tag)
    else
      allocation_tags = @allocation_tag.related.join(',')
      @students       = Assignment.list_students_by_allocations(allocation_tags) #alunos participantes da atividade
    end
  end

  def manage_groups
    deleted_groups_ids = params['deleted_groups_divs_ids'].blank? ? [] : params['deleted_groups_divs_ids'].collect{ |group| group.tr('_', ' ').split[1] } #"group_2" => 2
    @allocation_tag = AllocationTag.find(active_tab[:url][:allocation_tag_id])
   
    unless params['btn_cancel'] # clicou em "salvar"
      begin
        academic_allocation = AcademicAllocation.find_by_allocation_tag_id_and_academic_tool_id_and_academic_tool_type(@allocation_tag.id, @assignment.id, 'Assignment')

        # verifica se ainda está no prazo
        raise t(:date_range_expired, scope: [:assignment, :notifications]) unless @assignment.assignment_in_time?(@allocation_tag, current_user.id)

        GroupAssignment.transaction do
          deleted_groups_ids.each do |deleted_group_id| # deleção de grupos
            GroupAssignment.find(deleted_group_id).destroy unless (not GroupAssignment.can_remove_group?(deleted_group_id))
          end

          # params['groups'] = {"0"=>{"group_id"=>"1", "group_name"=>"grupo1", "student_ids"=>"1 2"}, "1"=>{"group_id"=>"2", "group_name"=>"grupo2", "student_ids"=>"3"}}
          params['groups'].each do |group| # criação/edição de grupos
            group_id = group[1]['group_id'] #["0", {"group_id"=>"1", "group_name"=>"grupo1", "student_ids"=>"1 2"}] => 1
            group_participants_ids = (group[1]['student_ids'].split).collect{|participant| participant.to_i} unless group[1]['student_ids'].nil? #or group[1]['student_ids'] == 0 # => "1 2" => ["1","2"] => [1,2]
            unless group_id.nil? # se não forem alunos sem grupo
              group_name = group[1]['group_name']
              if group_id == '0' # novo grupo
                group_assignment = GroupAssignment.create!(academic_allocation_id: academic_allocation.id, group_name: group_name)
              else # grupo já existente
                group_assignment = GroupAssignment.find(group_id)
                group_assignment.update_attributes!(group_name: group_name)
              end
            end

            # altera os alunos de grupo a não ser que o grupo não possa ser alterado/excluido e que este esteja na lista de grupos que foram excluídos
            change_students_group(group_assignment, group_participants_ids, academic_allocation.id) unless ((not GroupAssignment.can_remove_group?(group_id)) and deleted_groups_ids.include?("#{group_id}"))
          end
          @students_without_group = @assignment.students_without_groups(@allocation_tag)
          render 'group_assignment_content_div', layout: false
        end
      rescue Exception => error
        render :json => { success: false, flash_msg: error.message, flash_class: 'alert'}
      end
    else # clicou em "cancelar"
      @students_without_group = @assignment.students_without_groups(@allocation_tag)
      render 'group_assignment_content_div', layout: false
    end
  end

  def evaluate
    @assignment = Assignment.find(params[:id])
    authorize! [:evaluate, :update], @assignment

    @student_id = (params[:student_id].nil? or params[:student_id].blank?) ? nil : params[:student_id]
    @group_id   = (params[:group_id].nil? or params[:group_id].blank?) ? nil : params[:group_id]
    grade       = params['grade'].blank? ? params['grade'] : params['grade'].tr(',', '.') 
    begin
      @allocation_tag = AllocationTag.find(active_tab[:url][:allocation_tag_id])
      raise t(:date_range_expired, :scope => [:assignment, :notifications]) unless @assignment.on_evaluation_period?(@allocation_tag, current_user.id) # verifica se está no prazo
      academic_allocation = AcademicAllocation.find_by_allocation_tag_id_and_academic_tool_id_and_academic_tool_type(@allocation_tag.id, @assignment.id, 'Assignment')
      @sent_assignment = SentAssignment.find_or_create_by_academic_allocation_id_and_user_id_and_group_assignment_id(academic_allocation.id, @student_id, @group_id)
      @sent_assignment.update_attributes!(:grade => grade)
      @situation       = @assignment.situation_of_student(@allocation_tag.id, @student_id, @group_id)
      respond_to do |format|
        format.html { render 'evaluate_assignment_div', :layout => false }
      end
    rescue Exception => error
      render :json => { :success => false, :flash_msg => error.message.split(',')[0], :flash_class => 'alert' }
    end
  end

  def send_comment
    comment           = params[:comment_id].nil? ? nil : AssignmentComment.find(params[:comment_id]) # verifica se comentário já existe. se sim, é edição; se não, é criação.
    authorize! :send_comment, comment unless comment.nil?
    student_id        = params[:student_id].nil? ? nil : params[:student_id]
    group_id          = params[:group_id].nil? ? nil : params[:group_id]
    comment_text      = params['comment']
    comment_files     = params['comment_files'].nil? ? [] : params['comment_files']
    deleted_files_ids = params['deleted_files'].nil? ? [] : params['deleted_files'][0].split(",") # ["id_arquivo_del1,id_arquivo_del2"] => ["id_arquivo_del1", "id_arquivo_del2"]
    @allocation_tag = AllocationTag.find(active_tab[:url][:allocation_tag_id])
    academic_allocation = AcademicAllocation.find_by_allocation_tag_id_and_academic_tool_id_and_academic_tool_type(@allocation_tag.id,@assignment.id, 'Assignment')      
    sent_assignment = SentAssignment.find_or_create_by_academic_allocation_id_and_user_id_and_group_assignment_id(academic_allocation.id, student_id, group_id)
    #sent_assignment   = SentAssignment.find_or_create_by_group_assignment_id_and_assignment_id_and_user_id(group_id, @assignment.id, student_id) # busca ou cria sent_assignment ao aluno/grupo

    begin
      raise t(:date_range_expired, :scope => [:assignment, :notifications]) unless @assignment.on_evaluation_period?(@allocation_tag,current_user.id) # verifica se está no prazo
      ActiveRecord::Base.transaction do

        if comment.nil?
          comment = AssignmentComment.create!(:user_id => current_user.id, :comment => comment_text, :sent_assignment_id => sent_assignment.id, :updated_at => Time.now)
        else
          comment.update_attributes!(:comment => comment_text, :updated_at => Time.now)
        end

        comment_files.each do |file|
          CommentFile.create!({ :attachment => file, :assignment_comment_id => comment.id })
        end

        deleted_files_ids.each do |deleted_file_id|
          CommentFile.find(deleted_file_id).delete_comment_file unless deleted_file_id.blank?
        end
      end

      flash[:notice] = t(:comment_sent_success, :scope => [:assignment, :comments])
    rescue Exception => error
      flash[:alert] = error.message
    end

    redirect_to request.referer.nil? ? home_url(:only_path => false) : request.referer
  end

  def remove_comment
    comment = AssignmentComment.find(params[:comment_id])
    @allocation_tag = AllocationTag.find(active_tab[:url][:allocation_tag_id])
    authorize! :remove_comment, comment
    begin
      raise t(:date_range_expired, :scope => [:assignment, :notifications]) unless @assignment.on_evaluation_period?(@allocation_tag,current_user.id) # verifica se está no prazo
      ActiveRecord::Base.transaction do
        comment.comment_files.each do |file|
          file.delete_comment_file
        end
        comment.delete
      end
      render :json => { :success => true, :flash_msg => t(:removed_comment, :scope => [:assignment, :comments]), :flash_class => 'notice' }
    rescue Exception => error
      render :json => { :success => false, :flash_msg => error.message, :flash_class => 'alert' }
    end
  end

  ## Portfolio
  def download_public_files
    authorize! :download_files, Assignment

    file = PublicFile.find(params[:file_id])
    raise CanCan::AccessDenied unless @allocation_tag.related.include?(file.allocation_tag_id) # verify participation in class

    download_file(:back, file.attachment.path, file.attachment_file_name)
  end

  ## Portfolio - download files
  def download_files
    assignment = Assignment.find(params[:assignment_id])
    authorize! :download_files, assignment

    student_id = @allocation_tag.is_user_class_responsible?(current_user) ? params[:student_id] : current_user.id
    raise CanCan::AccessDenied unless assignment.user_can_access_assignment?(@allocation_tag, current_user.id, student_id, params[:group_id])

    file_path, file_name = if params[:zip]
      zipped_file_path_to_download(params[:type], assignment, @allocation_tag)
    else
      file_path_to_download(params[:type], params[:file_id], @allocation_tag)
    end

    redirect = request.referer.nil? ? home_url(only_path: false) : request.referer
    download_file(redirect, file_path, file_name)
  end # download files

  def send_public_files_page
    render layout: false
  end

  def upload_file
    begin
      allocation_tag = AllocationTag.find(active_tab[:url][:allocation_tag_id])
      case params[:type]
        when "public"
          raise CanCan::AccessDenied unless Profile.student_from_class?(current_user.id, allocation_tag.id)
          @public_file = PublicFile.create!({ attachment: params[:public_file], user_id: current_user.id, allocation_tag_id: allocation_tag.id })
        when "assignment"
          assignment = Assignment.find(params[:assignment_id])
          authorize! :upload_file, assignment

          group = GroupAssignment.first(
                  joins: :academic_allocation,
                  include: :group_participants,
                  conditions: ["group_participants.user_id = #{current_user.id} 
                  AND academic_allocations.academic_tool_id = #{assignment.id}"])
          group_id = group.nil? ? nil : group.id
          user_id  = group.nil? ? current_user.id : nil

          # verifica, se é responsável da classe ou aluno que esteja acessando informações dele mesmo
          raise CanCan::AccessDenied unless assignment.user_can_access_assignment?(allocation_tag, current_user.id, current_user.id, group_id)
          raise t(:date_range_expired, scope: [:assignment, :notifications]) unless assignment.assignment_in_time?(allocation_tag, current_user.id) # verifica período para envio do arquivo

          academic_allocation = AcademicAllocation.find_by_allocation_tag_id_and_academic_tool_id_and_academic_tool_type(allocation_tag.id,assignment.id, 'Assignment')
          sent_assignment     = SentAssignment.find_or_create_by_academic_allocation_id_and_user_id_and_group_assignment_id!(academic_allocation.id, user_id, group_id)
          @assignment_file    = AssignmentFile.create!({ attachment: params[:assignment_file], sent_assignment_id: sent_assignment.id, user_id: current_user.id })
      end # case

      flash[:notice] = t(:uploaded_success, scope: [:assignment, :files])
    rescue => error
      flash[:alert] = error.message.split(',')[0]
    end
    redirect_to (request.referer.nil? ? home_url(only_path: false) : request.referer)
  end

  def delete_file
    begin
      case params[:type]
        when 'public'
          @public_file = PublicFile.find(params[:file_id])
          raise CanCan::AccessDenied unless @public_file.user_id == current_user.id

          if @public_file.delete
            File.delete(@public_file.attachment.path) if File.exist?(@public_file.attachment.path)
          else
            raise t(:error_delete, :scope => [:assignment, :files])
          end
        when 'assignment'
          assignment = Assignment.find(params[:assignment_id])
          authorize! :delete_file, assignment

          allocation_tag = AllocationTag.find(active_tab[:url][:allocation_tag_id])

          raise t(:date_range_expired, :scope => [:assignment, :notifications]) unless assignment.assignment_in_time?(allocation_tag, current_user.id) # verifica prazo
          # verifica, se é responsável da classe ou aluno que esteja acessando informações dele mesmo
          raise CanCan::AccessDenied unless assignment.user_can_access_assignment?(allocation_tag, current_user.id, AssignmentFile.find(params[:file_id]).user_id)

          @assignment_file = AssignmentFile.find(params[:file_id])
          @assignment_file.delete_assignment_file
      end
      flash[:notice] = t(:deleted_success, :scope => [:assignment, :files])
    rescue Exception => error
      flash[:alert] = error.message
    end
    redirect_to (request.referer.nil? ? home_url(:only_path => false) : request.referer)
  end

  ##
  # Página de importação de grupos (lightbox)
  # => @assignments: todas as atividades da turma acessada pelo usuário no momento
  # => @assignment_id: a atividade que irá importar os grupos
  ##
  def import_groups_page
    group_id       = AllocationTag.find(active_tab[:url][:allocation_tag_id]).group_id
    @assignments   = GroupAssignment.all_by_group_id(group_id)
    @allocation_tag = AllocationTag.find(active_tab[:url][:allocation_tag_id])
    @assignments.delete(@assignment)
    render :layout => false
  end

  def import_groups
    import_to_assignment_id   = params[:id] # para qual atividade os grupos serão importados
    import_from_assignment_id = params[:assignment_id_import_from] # de qual atividade os grupos serão importados
    allocation_tag = AllocationTag.find(active_tab[:url][:allocation_tag_id])
    groups_to_import          = GroupAssignment.all_by_assignment_id(import_from_assignment_id, allocation_tag.id) # grupos a serem importados

    begin 
      # verifica período para envio do arquivo
      raise t(:date_range_expired, scope: [:assignment, :notifications]) unless @assignment.assignment_in_time?(allocation_tag, current_user.id) 

      academic_allocation = AcademicAllocation.find_by_allocation_tag_id_and_academic_tool_id_and_academic_tool_type(allocation_tag.id, import_to_assignment_id, 'Assignment')

      unless groups_to_import.empty?
        groups_to_import.each do |group_to_import|
          group_imported = GroupAssignment.create(group_name: group_to_import.group_name, academic_allocation_id: academic_allocation.id)  # grupo importado
          group_to_import.group_participants.each do |participant_to_import|
            GroupParticipant.create(group_assignment_id: group_imported.id, user_id: participant_to_import.user_id)
          end
        end
      end

      flash[:notice] = t(:import_success, scope: [:assignment, :import_groups])

    rescue Exception => error
      flash[:alert] = error.message
    end
    redirect_to information_assignment_path(@assignment)
  end

  private

    def zipped_file_path_to_download(type, assignment, allocation_tag)
      folder_name = ''
      case type
        when 'assignment'
          sent_assignment = assignment.sent_assignments.where(user_id: params[:student_id], group_assignment_id: params[:group_id]).first

          raise CanCan::AccessDenied unless sent_assignment.user_can_access?(current_user, allocation_tag)

          folder_name     = [assignment.name, (params[:group_id].nil? ? sent_assignment.user.nick : sent_assignment.group_assignment.group_name)].join(' - ') # activity I - Student I
          all_files       = sent_assignment.assignment_files
        when 'enunciation'
          folder_name = assignment.name
          all_files = assignment.assignment_enunciation_files
      end

      file_path = compress({ files: all_files, table_column_name: 'attachment_file_name', name_zip_file: folder_name })
      [file_path || nil, nil]
    end

    def file_path_to_download(type, file_id, allocation_tag)
      file = case type
        when 'comment' # arquivo de um comentário
          CommentFile.find(file_id)
        when 'assignment' # arquivo enviado pelo aluno/grupo
          AssignmentFile.find(file_id)
        when 'enunciation' # arquivo que faz parte da descrição da atividade
          AssignmentEnunciationFile.find(file_id)
      end

      raise CanCan::AccessDenied if file.respond_to?(:sent_assignment) and not file.sent_assignment.user_can_access?(current_user, allocation_tag)

      [file.attachment.path, file.attachment_file_name]
    end

    ##
    # Método que realiza as mudanças de um grupo e realiza as trocas de alunos
    ##
    def change_students_group(group_assignment, students_ids, academic_allocation_id)
      unless students_ids.nil?
        students_ids.each do |student_id|
          # groupo atual do aluno nesta atividade
          current_group_participant = GroupParticipant.includes(:group_assignment).where(group_assignments: {academic_allocation_id: academic_allocation_id}, group_participants: {user_id: student_id}).first

          # sent_assignment do grupo atual
          current_group_sent_assignment = current_group_participant.group_assignment.sent_assignment unless current_group_participant.nil?
          student_files_current_group   = current_group_sent_assignment.assignment_files.where(user_id: student_id) unless current_group_sent_assignment.nil?

          # sent_assignment do grupo ao qual aluno tentará ser movido
          choosen_group_sent_assignment = group_assignment.sent_assignment unless group_assignment.nil?

          student_can_be_removed_from_current_group = (student_files_current_group.blank? and (current_group_sent_assignment.nil? or current_group_sent_assignment.grade.blank?))
          student_can_be_moved_to_choosen_group     = (choosen_group_sent_assignment.nil? or choosen_group_sent_assignment.grade.nil?)
          
          # se:
            # => aluno não enviou arquivos ao grupo atual E sent_assignment do grupo não existe ou não foi avaliado
            # => novo grupo não tenha sent_assignment ou não tenha sido avaliado
          if (student_can_be_removed_from_current_group and student_can_be_moved_to_choosen_group)
            unless group_assignment.nil?
              if current_group_participant.nil?
                GroupParticipant.create!(group_assignment_id: group_assignment["id"], user_id: student_id)
              elsif current_group_participant.group_assignment_id != group_assignment.id
                current_group_participant.update_attribute(:group_assignment_id, group_assignment.id)
              end
            else
              current_group_participant.delete unless current_group_participant.nil? 
            end
          end # end if
        end
      end # end unless
    end

end
