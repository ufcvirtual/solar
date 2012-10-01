class ScoresController < ApplicationController

  before_filter :prepare_for_group_selection, :only => [:show, :index]
  before_filter :prepare_for_pagination, :only => [:index]

  ##
  # Lista informacoes de acompanhamento do aluno
  ##
  def show
    authorize! :show, Score

    student_id = params[:student_id] || current_user.id
    class_id = AllocationTag.find(active_tab[:url]['allocation_tag_id']).group_id
    @student = User.find(student_id)
    related_allocations = AllocationTag.find_related_ids(Group.find(class_id).allocation_tag.id) #allocations relacionadas à turma

    authorize! :find, @student #verifica se o usuario logado tem permissao para consultar o usuario informado
    authorize! :index,  AllocationTag.user_allocation_tag_related_with_class(class_id, current_user.id) #verifica se pode acessar turma

    @individual_activities = Assignment.student_assignments_info(class_id, student_id, Individual_Activity)
    @group_activities = Assignment.student_assignments_info(class_id, student_id, Group_Activity)
    @discussions = Discussion.all_by_allocations_and_student_id(related_allocations, student_id)

    from_date = Date.today << 2 #dois meses atras
    until_date = Date.today
    @amount = Score.find_amount_access_by_student_id_and_interval(active_tab[:url]['id'], @student.id, from_date, until_date)
  end

  ##
  # Quantidade de acessos do aluno a unidade curricular
  ##
  def amount_history_access
    authorize! :show, Score

    @student_id = params[:id]
    curriculum_unit_id = active_tab[:url]['id']
    class_id = AllocationTag.find(active_tab[:url]['allocation_tag_id']).group_id

    authorize! :find, User.find(@student_id) #verifica autorizacao para consultar dados do usuario
    authorize! :index,  AllocationTag.user_allocation_tag_related_with_class(class_id, current_user.id) #verifica se pode acessar turma

    # validar as datas
    @from_date = date_valid?(params['from-date']) ? Date.parse(params['from-date']) : Date.today << 2
    @until_date = date_valid?(params['until-date']) ? Date.parse(params['until-date']) : Date.today

    @amount = Score.find_amount_access_by_student_id_and_interval(curriculum_unit_id, @student_id, @from_date, @until_date)

    render :layout => false
  end

  ##
  # Historico de acesso do aluno
  ##
  def history_access
    authorize! :show, Score

    student_id = params['id']
    curriculum_unit_id = active_tab[:url]["id"]
    class_id = AllocationTag.find(active_tab[:url]['allocation_tag_id']).group_id
    
    authorize! :find, User.find(student_id) #verifica autorizacao para consultar dados do usuario
    authorize! :index,  AllocationTag.user_allocation_tag_related_with_class(class_id, current_user.id) #verifica se pode acessar turma
    
    from_date = Date.today << 2 unless date_valid?(@from_date)
    until_date = Date.today unless date_valid?(@until_date)

    @history = Score.history_student_id_and_interval(curriculum_unit_id, student_id, from_date, until_date)

    render :layout => false
  end

  ##
  # Lista de informações gerais do acompanhamento de todos os alunos da turma
  ##
  def index
    authorize! :index, Score #verifica se pode acessar método
    curriculum_unit_id = active_tab[:url]['id']
    allocation_tag_id = active_tab[:url]['allocation_tag_id']
    @group = Group.joins(:allocation_tag).where("allocation_tags.id = #{allocation_tag_id}").first
    authorize! :index,  AllocationTag.user_allocation_tag_related_with_class(@group.id, current_user.id) #verifica se pode acessar turma

    unless @group.nil?
      @assignments = Assignment.all(:joins => [:allocation_tag, :schedule], :conditions => ["allocation_tags.group_id = 
        #{@group.id}"], :select => ["assignments.id", "schedule_id", "type_assignment", "name"]) #assignments da turma
      allocation_tags = AllocationTag.find_related_ids(@group.allocation_tag.id).join(',') #allocations relacionadas à turma.join(',')
      @students = Assignment.list_students_by_allocations(allocation_tags)
      @scores = Score.students_information(@students, @assignments, curriculum_unit_id, @group.allocation_tag.id) #dados dos alunos nas atividades
    end

  end

  private

  ##
  # Verifica se a data tem um formato valido
  ##
  def date_valid?(date)
    begin
      return true if Date.parse date
    rescue
      return false
    end
  end

end
