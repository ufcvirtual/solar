module V1
  class Sav < Base
    namespace :sav

    before do
      verify_ip_access!
    end

    desc "Todos os perfis"
    get :profiles, rabl: "sav/profiles" do
      @profiles = Profile.all_except_basic
    end

    desc "Todos os tipos de curso"
    get "/course/types", rabl: "sav/course_types" do
      @types = CurriculumUnitType.all
    end

    desc "Todos os semestres"
    get :semesters, rabl: "sav/semesters" do
      @semesters = Semester.order('name desc').uniq
    end

    desc "Todas as disciplinas por semestre e curso"
    params do
      requires :semester, type: String
      requires :course_id, type: Integer
    end
    get :disciplines, rabl: "sav/disciplines" do
      @disciplines = CurriculumUnit.joins(offers: [:course, :semester]).where("semesters.name = ?", params[:semester]).where(courses: {id: params[:course_id]})
    end

    # -- turmas
    #   -- periodo, tipo
    #   -- periodo, curso
    #   -- periodo, curso, disciplina
    desc "Todas as turmas por tipo de curso, semestre, curso ou disciplina"
    params do
      requires :semester, type: String
      optional :course_id, type: Integer
      optional :discipline_id, type: Integer
    end
    get :groups, rabl: "sav/groups" do
      query = ["semesters.name = :semester", "groups.status IS TRUE"]
      query << "offers.course_id = :course_id" if params[:course_id].present?
      query << "offers.curriculum_unit_id = :discipline_id" if params[:discipline_id].present?

      @groups = Group.joins(offer: :semester).where(query.join(' AND '), params.slice(:semester, :course_id, :discipline_id))
    end
  end
end
