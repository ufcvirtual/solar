module V1
  class Offers < Base

     segment do

      before { verify_ip_access! }

      namespace :offer do 
        desc "Criação de oferta/semestre"
        params do
          requires :name, type: String
          requires :offer_start, :offer_end, type: Date
          optional :enrollment_start, :enrollment_end, type: Date
          optional :course_id, type: Integer#, values: -> { Course.all.map(&:id) }
          optional :curriculum_unit_id, type: Integer#, values: -> { CurriculumUnit.all.map(&:id) }
          optional :course_code, type: String#, values: -> { Course.all.map(&:code).compact }
          optional :curriculum_unit_code, type: String#, values: -> { CurriculumUnit.all.map(&:code).compact }
          exactly_one_of :course_code, :course_id
          exactly_one_of :curriculum_unit_code, :curriculum_unit_id
        end
        post "/" do
          begin
            course_id          = (params[:course_code].present? ? Course.find_by_code(params[:course_code]).try(:id) : params[:course_id])
            curriculum_unit_id = (params[:curriculum_unit_code].present? ? CurriculumUnit.find_by_code(params[:curriculum_unit_code]).try(:id) : params[:curriculum_unit_id])
            offer = creates_offer_and_semester(params[:name], {start_date: params[:offer_start].try(:to_date), end_date: params[:offer_end].try(:to_date)}, {start_date: params[:enrollment_start], end_date: params[:enrollment_end]}, {curriculum_unit_id: curriculum_unit_id, course_id: course_id})
            {id: offer.id}
          end
        end

        desc "Edição de oferta"
        params do
          optional :offer_start, :offer_end, :enrollment_start, :enrollment_end, type: Date
          at_least_one_of :offer_start, :offer_end, :enrollment_start, :enrollment_end
        end
        put ":id" do
          begin
            update_dates(Offer.find(params[:id]), params)
            {ok: :ok}
          end
        end
      end # offer

      desc "Todos os semestres"
      get :semesters, rabl: "semesters/list" do
        @semesters = Semester.order('name desc').uniq
      end

    end # segment

  end
end
