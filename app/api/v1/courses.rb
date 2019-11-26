module V1
  class Courses < Base

    segment do
      before { verify_ip_access_and_guard! }

      namespace :courses do
        desc "Todos os cursos por tipo e semestre"
        params do
          requires :semester, type: String
          requires :course_type_id, type: Integer#, values: -> { CurriculumUnitType.all.map(&:id) }
        end
        get "/", rabl: "courses/list" do
          @courses = Course.joins(offers: [:curriculum_unit, :semester]).where("semesters.name = :semester AND curriculum_units.curriculum_unit_type_id = :course_type_id", params.slice(:semester, :course_type_id))
        end
      end # courses

      namespace :course do
        desc "Criação de curso"
        params { requires :name, :code, type: String }
        post "/" do
          begin
            course = Course.create! course_params(params)
            {id: course.id}
          end
        end

        desc "Edição de curso"
        params do
          requires :id, type: Integer#, values: -> { Course.all.map(&:id) }
          optional :name, :code, type: String
          at_least_one_of :code, :name
        end
        put ":id" do
          begin
            Course.find(params[:id]).update_attributes! course_params(params)
            {ok: :ok}
          end
        end

        desc "Todos os tipos de curso"
        get "types", rabl: "curriculum_units/types" do
          @types = CurriculumUnitType.all
        end
      end # course
    end #segment

    segment do
      before{ guard_client! }

      namespace :my_courses do
        desc "Todos os cursos da aplicação cliente"
        get "/", rabl: "courses/list" do
          ats = AllocationTagOwner.where(oauth_application_id: @current_client.id).map(&:allocation_tag)
          @courses = ats.map(&:get_course).uniq
        end
      end
    end

  end
end