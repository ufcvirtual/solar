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

              offer = get_offer(params[:curriculum_unit], params[:course], params[:period])
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
        params do
          optional :code, type: String
          optional :status, type: Boolean
          at_least_one_of :code, :status
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

    end # segment

  end
end
