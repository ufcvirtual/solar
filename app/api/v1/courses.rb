module V1
  class Courses < Base

    segment do

      before { verify_ip_access! }

      namespace :sav do

        desc "Todos os cursos por tipo e semestre"
        params do
          requires :semester, type: String
          requires :course_type_id, type: Integer
        end
        get :courses, rabl: "sav/courses" do
          # ao colocar campo de tipo de curso em courses, refazer consulta - 10/2014
          @courses = Course.joins(offers: [:curriculum_unit, :semester]).where("semesters.name = :semester AND curriculum_units.curriculum_unit_type_id = :course_type_id", params.slice(:semester, :course_type_id))
        end

      end # sav

      namespace :integration do

        namespace :course do 
          desc "Criação de curso"
          params { requires :name, :code }
          post "/" do
            begin
              course = Course.create! course_params(params)
              {id: course.id}
            rescue => error
              error!(error, 422)
            end
          end

          desc "Edição de curso"
          params { optional :name, :code }
          put ":id" do
            begin
              Course.find(params[:id]).update_attributes! course_params(params)
              {ok: :ok}
            rescue => error
              error!(error, 422)
            end
          end
        end # course

      end # integration

    end # segment

  end
end