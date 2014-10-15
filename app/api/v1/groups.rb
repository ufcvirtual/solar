module V1
  class Groups < Base

    segment do

      before { guard! }

      namespace :curriculum_units do

        desc "Turmas de uma UC do usuario"
        params { requires :id, type: Integer }
        get ":id/groups", rabl: "groups/list" do
          user_groups    = current_user.groups(nil, Allocation_Activated).map(&:id)
          current_offers = Offer.currents(Date.today, true).pluck(:id)

          @groups = CurriculumUnit.find(params[:id]).groups.where(groups: {id: user_groups, offer_id: current_offers}) rescue []
        end

      end # curriculum_units

    end # segment

    segment do

      before { verify_ip_access! }

      namespace :groups do

        # integration/groups/merge
        namespace :merge do
          desc "Aglutinação/Desaglutinação de turmas"
          params do
            requires :main_group, :course, :curriculum_unit, :period, type: String  
            requires :secundary_groups, type: Array
            optional :type, type: Boolean, default: true # if true: merge; if false: undo merge
          end

          put "/" do
            begin
              if params[:type]
                replicate_content_groups, receive_content_groups = params[:secundary_groups], [params[:main_group]]
              else
                replicate_content_groups, receive_content_groups = [params[:main_group]], params[:secundary_groups]
              end

              offer = get_offer(params[:curriculum_unit], params[:course], nil, params[:period])
              ActiveRecord::Base.transaction do
                replicate_content_groups.each do |replicate_content_group_code|
                  replicate_content_group = get_offer_group(offer, replicate_content_group_code)
                  receive_content_groups.each do |receive_content_group_code|
                    receive_content_group = get_offer_group(offer, receive_content_group_code)
                    replicate_content(replicate_content_group, receive_content_group, params[:type])
                  end
                end
              end
              offer.notify_editors_of_disabled_groups(Group.where(code: params[:secundary_groups])) if params[:type]

              {ok: :ok}
            rescue ActiveRecord::RecordNotFound
              error!({error: I18n.t(:object_not_found)}, 404)
            rescue => error
              error!({error: error}, 422)
            end
          end # /

        end # merge

        # -- turmas
        #   -- periodo, tipo
        #   -- periodo, curso
        #   -- periodo, curso, disciplina
        desc "Todas as turmas por tipo de curso, semestre, curso ou disciplina"
        params do
          requires :semester, type: String
          optional :course_type_id, :course_id, :discipline_id, type: Integer
        end
        get "/", rabl: "groups/index" do
          query = ["semesters.name = :semester", "groups.status IS TRUE"]
          query << "curriculum_units.curriculum_unit_type_id = :course_type_id" if params[:course_type_id].present?
          query << "offers.course_id = :course_id" if params[:course_id].present?
          query << "offers.curriculum_unit_id = :discipline_id" if params[:discipline_id].present?

          @groups = Group.joins(offer: [:semester, :curriculum_unit]).where(query.join(' AND '), params.slice(:course_type_id, :semester, :course_id, :discipline_id))
        end

      end # groups

      namespace :group do 
        desc "Criação de turma"
        params do
          requires :code, type: String
          requires :offer_id, type: Integer
        end
        post "/" do
          begin
            group = Group.create! group_params(params)
            {id: group.id}
          rescue => error
            error!(error, 422)
          end
        end

        desc "Edição de turma"
        # não edita nome do semestre. se for o caso, deleta a antiga oferta e cria uma nova com o nome certo do semestre
        params do
          optional :code, type: String
          optional :status, type: Boolean
        end
        put ":id" do
          begin
            group = Group.find(params[:id])
            group.update_attributes! group_params(params)
            group.offer.notify_editors_of_disabled_groups(group) if params[:status].present? and not(params[:status])

            {ok: :ok}
          rescue => error
            error!(error, 422)
          end
        end
      end # group

      namespace :load do

        namespace :groups do
          # POST load/groups
          post "/" do
            load_group    = params[:turmas]
            cpfs          = load_group[:professores]
            semester_name = load_group[:periodo].blank? ? load_group[:ano] : "#{load_group[:ano]}.#{load_group[:periodo]}"
            offer_period  = { start_date: load_group[:dtInicio].to_date, end_date: load_group[:dtFim].to_date }
            course        = Course.find_by_code! load_group[:codGraduacao]
            uc            = CurriculumUnit.find_by_code! load_group[:codDisciplina]

            begin
              ActiveRecord::Base.transaction do 
                semester = verify_or_create_semester(semester_name, offer_period)
                offer    = verify_or_create_offer(semester, {curriculum_unit_id: uc.id, course_id: course.id}, offer_period)
                group    = verify_or_create_group({offer_id: offer.id, code: load_group[:codigo]})

                allocate_professors(group, cpfs)
              end

              {ok: :ok}
            rescue => error
              error!({error: error}, 422)
            end
          end

          # POST load/groups/enrollments
          post :enrollments do
            load_enrollments = params[:matriculas]
            user             = verify_or_create_user(load_enrollments[:cpf])
            groups           = JSON.parse(load_enrollments[:turmas])
            student_profile  = 1 # Aluno => 1

            begin
              ActiveRecord::Base.transaction do
                groups = groups.collect do |group_info|
                  get_group(group_info["codDisciplina"], group_info["codGraduacao"], group_info["codigo"], group_info["periodo"], group_info["ano"]) unless group_info["codDisciplina"] == 78
                end # Se cód. graduação for 78, desconsidera (por hora, vem por engano).

                cancel_previous_and_create_allocations(groups.compact, user, student_profile)
              end

              {ok: :ok}
            rescue => error
              error!({error: error}, 422)
            end
          end

          # GET load/groups/enrollments
          params { requires :codDisciplina, :codGraduacao, :codTurma, :periodo, :ano, type: String }
          get :enrollments, rabl: "users/enrollments" do
            group  = get_group(params[:codDisciplina], params[:codGraduacao], params[:codTurma], params[:periodo], params[:ano])
            raise ActiveRecord::RecordNotFound if group.nil?
            begin 
              @users = group.students_participants.map(&:user)
            rescue  => error
              error!({error: error}, 422)
            end
          end

        end # groups

      end # load

      namespace :sav do

        # -- turmas
        #   -- periodo, tipo
        #   -- periodo, curso
        #   -- periodo, curso, disciplina
        desc "Todas as turmas por tipo de curso, semestre, curso ou disciplina"
        params do
          requires :semester, type: String
          optional :course_type_id, :course_id, :discipline_id, type: Integer
        end
        get :groups, rabl: "groups/index" do
          query = ["semesters.name = :semester", "groups.status IS TRUE"]
          query << "curriculum_units.curriculum_unit_type_id = :course_type_id" if params[:course_type_id].present?
          query << "offers.course_id = :course_id" if params[:course_id].present?
          query << "offers.curriculum_unit_id = :discipline_id" if params[:discipline_id].present?

          @groups = Group.joins(offer: [:semester, :curriculum_unit]).where(query.join(' AND '), params.slice(:course_type_id, :semester, :course_id, :discipline_id))
        end
        
      end # sav

    end # segment

  end
end
