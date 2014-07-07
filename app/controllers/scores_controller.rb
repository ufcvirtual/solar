class ScoresController < ApplicationController

  before_filter :prepare_for_group_selection, :only => [:index]
  before_filter :prepare_for_pagination, :only => [:index]

  ##
  # Lista de informações gerais do acompanhamento de todos os alunos da turma
  ##
  def index
    curriculum_unit_id, allocation_tag_id = active_tab[:url][:id], active_tab[:url][:allocation_tag_id]
    authorize! :index, Score, on: [allocation_tag_id] # verifica se pode acessar método

    @group = AllocationTag.find(allocation_tag_id).groups.first
    @allocation_tag = AllocationTag.find(allocation_tag_id)

    raise CanCan::AccessDenied if @group.nil? # turma nao existe
    # authorize! :related_with_allocation_tag, AllocationTag.user_allocation_tag_related_with_class(@group.id, current_user.id) # verifica se pode acessar turma

    @curriculum_unit = CurriculumUnit.find(curriculum_unit_id)
    @assignments = Assignment.all(:joins => [{academic_allocations: :allocation_tag}, :schedule],
      :conditions => ["allocation_tags.group_id = #{@group.id}"], 
      :select => ["assignments.id", "schedule_id", "type_assignment", "name"])

       # atividades da turma
    allocation_tags = AllocationTag.find_related_ids(allocation_tag_id).join(',')
    @students = Assignment.list_students_by_allocations(allocation_tags)
    @scores = Score.students_information(@students, @assignments, @group) # dados dos alunos nas atividades
  end

  ##
  # Lista informacoes de acompanhamento do aluno
  ##
  def show
    authorize! :show, Score, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    @student = params.include?(:student_id) ? User.find(params[:student_id]) : current_user

    allocation_tag = AllocationTag.find(allocation_tag_id)
    group_id            = allocation_tag.group_id
    related_allocations = allocation_tag.related

    authorize! :find, @student # verifica se o usuario logado tem permissao para consultar o usuario informado

    @individual_activities = Assignment.student_assignments_info(group_id, @student.id, Assignment_Type_Individual)
    @group_activities      = Assignment.student_assignments_info(group_id, @student.id, Assignment_Type_Group)
    @discussions           = Discussion.posts_count_by_user(@student.id, related_allocations)

    from_date, until_date  = (Date.today << 2), Date.today # dois meses atras
    at      = AllocationTag.find_by_curriculum_unit_id(active_tab[:url][:id]).id
    @amount = Score.find_amount_access_by_student_id_and_interval(at, @student.id, from_date, until_date)
  end

  ##
  # Quantidade de acessos do aluno a unidade curricular
  ##
  def amount_history_access
    authorize! :show, Score

    @student_id = params[:id]

    authorize! :find, User.find(@student_id) # verifica autorizacao para consultar dados do usuario
    # authorize! :related_with_allocation_tag,  AllocationTag.user_allocation_tag_related_with_class(group_id, current_user.id) # verifica se pode acessar turma
    
    from_date  = date_valid?(params['from-date']) ? Date.parse(params['from-date']) : (Date.today << 2)
    until_date = date_valid?(params['until-date']) ? Date.parse(params['until-date']) : Date.today

    at = AllocationTag.find_by_curriculum_unit_id(active_tab[:url][:id]).id
    @amount = Score.find_amount_access_by_student_id_and_interval(at, @student_id, from_date, until_date)

    render :layout => false
  end

  ##
  # Historico de acesso do aluno
  ##
  def history_access
    authorize! :show, Score

    student_id = params[:id]
    
    authorize! :find, User.find(student_id) # verifica autorizacao para consultar dados do usuario
    # authorize! :related_with_allocation_tag,  AllocationTag.user_allocation_tag_related_with_class(class_id, current_user.id) # verifica se pode acessar turma
    
    from_date  = (date_valid?(params['from-date']) ? Date.parse(params['from-date']) : (Date.today << 2))
    until_date = (date_valid?(params['until-date']) ? Date.parse(params['until-date']) : Date.today)

    at = AllocationTag.find_by_curriculum_unit_id(active_tab[:url][:id]).id
    @history = Score.history_student_id_and_interval(at, student_id, from_date, until_date).order("created_at DESC")

    render :layout => false
  end

  private

    def date_valid?(date)
      begin
        return true if Date.parse date
      rescue
        return false
      end
    end

end
