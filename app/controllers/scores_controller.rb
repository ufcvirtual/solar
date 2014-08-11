class ScoresController < ApplicationController

  before_filter :prepare_for_group_selection, only: :index
  before_filter :prepare_for_pagination, only: :index

  ## Lista de informações gerais do acompanhamento de todos os alunos da turma
  def index
    allocation_tag_id = active_tab[:url][:allocation_tag_id]
    authorize! :index, Score, on: [allocation_tag_id] # verifica se pode acessar método

    @group = AllocationTag.find(allocation_tag_id).groups.first
    @allocation_tag = AllocationTag.find(allocation_tag_id)

    raise CanCan::AccessDenied if @group.nil? # turma nao existe

    @assignments = Assignment.joins({academic_allocations: :allocation_tag}).where("allocation_tags.group_id = ?", @group.id)
      .select("assignments.id, schedule_id, type_assignment, name").order("assignments.name")

    # atividades da turma
    allocation_tags = AllocationTag.find(allocation_tag_id).related.join(',')
    @students       = Assignment.list_students_by_allocations(allocation_tags)
    @scores         = Score.students_information(@students, @assignments, @group) # dados dos alunos nas atividades
  end

  ## Student / current student info
  def info
    authorize! :info, Score, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    @student = current_user

    informations(allocation_tag_id)
  end

  ## Professor / any student info
  def student_info
    authorize! :student_info, Score, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    authorize! :find, (@student = User.find(params[:student_id])) # verifica se o usuario logado tem permissao para consultar o usuario informado

    informations(allocation_tag_id)

    render :info
  end

  ## Quantidade de acessos do aluno a unidade curricular
  def amount_history_access
    begin
      authorize! :info, Score
    rescue
      authorize! :student_info, Score
    end

    @student_id = params[:id]

    authorize! :find, User.find(@student_id) # verifica autorizacao para consultar dados do usuario

    from_date  = date_valid?(params['from-date']) ? Date.parse(params['from-date']) : (Date.today << 2)
    until_date = date_valid?(params['until-date']) ? Date.parse(params['until-date']) : Date.today

    at      = AllocationTag.find_by_offer_id(active_tab[:url][:id]).id
    @amount = Score.find_amount_access_by_student_id_and_interval(at, @student_id, from_date, until_date)

    render layout: false
  end

  ## Historico de acesso do aluno
  def history_access
    begin
      authorize! :info, Score
    rescue
      authorize! :student_info, Score
    end

    student_id = params[:id]

    authorize! :find, User.find(student_id) # verifica autorizacao para consultar dados do usuario

    from_date  = (date_valid?(params['from-date']) ? Date.parse(params['from-date']) : (Date.today << 2))
    until_date = (date_valid?(params['until-date']) ? Date.parse(params['until-date']) : Date.today)

    at       = AllocationTag.find_by_offer_id(active_tab[:url][:id]).id
    @history = Score.history_student_id_and_interval(at, student_id, from_date, until_date).order("created_at DESC")

    render layout: false
  end

  private

    def informations(allocation_tag_id)
      allocation_tag = AllocationTag.find(allocation_tag_id)
      group_id, related_allocations = allocation_tag.group_id, allocation_tag.related

      @individual_activities = Assignment.student_assignments_info(group_id, @student.id, Assignment_Type_Individual)
      @group_activities      = Assignment.student_assignments_info(group_id, @student.id, Assignment_Type_Group)
      @discussions           = Discussion.posts_count_by_user(@student.id, related_allocations)

      from_date, until_date  = (Date.today << 2), Date.today # dois meses atras
      at      = AllocationTag.find_by_offer_id(active_tab[:url][:id]).id
      @amount = Score.find_amount_access_by_student_id_and_interval(at, @student.id, from_date, until_date)
    end

    def date_valid?(date)
      begin
        return true if Date.parse date
      rescue
        return false
      end
    end

end
