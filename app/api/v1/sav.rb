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

    desc "Todos os cursos por tipo e semestre"
    params do
      requires :semester, type: String
      requires :course_type_id, type: Integer
    end
    get :courses, rabl: "sav/courses" do
      # ao colocar campo de tipo de curso em courses, refazer consulta - 10/2014
      @courses = Course.joins(offers: [:curriculum_unit, :semester]).where("semesters.name = :semester AND curriculum_units.curriculum_unit_type_id = :course_type_id", params.slice(:semester, :course_type_id))
    end

    desc "Todas as disciplinas por tipo, semestre ou curso"
    params do
      requires :semester, type: String
      optional :course_type_id, type: Integer
      optional :course_id, type: Integer
    end
    get :disciplines, rabl: "sav/disciplines" do

      tb_joins = [:semester]
      tb_joins << :course if params[:course_id].present?

      query = ["semesters.name = :semester"]
      query << "curriculum_unit_type_id = :course_type_id" if params[:course_type_id].present?
      query << "courses.id = :course_id" if params[:course_id].present?

      @disciplines = CurriculumUnit.joins(offers: tb_joins).where(query.join(' AND '), params.slice(:semester, :course_type_id, :course_id))
    end

    # -- turmas
    #   -- periodo, tipo
    #   -- periodo, curso
    #   -- periodo, curso, disciplina
    desc "Todas as turmas por tipo de curso, semestre, curso ou disciplina"
    params do
      requires :semester, type: String
      optional :course_type_id, type: Integer
      optional :course_id, type: Integer
      optional :discipline_id, type: Integer
    end
    get :groups, rabl: "sav/groups" do
      query = ["semesters.name = :semester", "groups.status IS TRUE"]
      query << "curriculum_units.curriculum_unit_type_id = :course_type_id" if params[:course_type_id].present?
      query << "offers.course_id = :course_id" if params[:course_id].present?
      query << "offers.curriculum_unit_id = :discipline_id" if params[:discipline_id].present?

      @groups = Group.joins(offer: [:semester, :curriculum_unit]).where(query.join(' AND '), params.slice(:course_type_id, :semester, :course_id, :discipline_id))
    end
  end
end
