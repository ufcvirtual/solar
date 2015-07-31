module V1
  class Groups < Base

    segment do

      before { guard! }

      namespace :curriculum_units do

        desc "Turmas de uma UC do usuario"
        params { requires :id, type: Integer }#, values: -> { CurriculumUnit.all.map(&:id) } }
        get ":id/groups", rabl: "groups/list" do
          user_groups    = current_user.groups(nil, Allocation_Activated).map(&:id)
          current_offers = Offer.currents({verify_end_date: true})
          @groups = Group.joins(:offer).where(id: user_groups, offer_id: current_offers).where("offers.curriculum_unit_id = ?", params[:id]) rescue []
        end

      end # curriculum_units

    end # segment

    segment do

      before { verify_ip_access! }

      namespace :groups do

        namespace :merge do
          desc "Aglutinação/Desaglutinação de turmas"
          params do
            requires :main_group, :main_course, :main_curriculum_unit, :main_semester, type: String
            requires :secundary_groups, type: Array
            optional :type, type: Boolean, default: true # if true: merge; if false: undo merge
            optional :secundary_course, :secundary_curriculum_unit, :secundary_semester, type: String
          end

          put "/" do
            begin
              main_offer      = get_offer(params[:main_curriculum_unit], params[:main_course], params[:main_semester])
              secundary_offer = get_offer(params[:secundary_curriculum_unit] || params[:main_curriculum_unit], params[:secundary_course] || params[:main_course], params[:secundary_semester] || params[:main_semester])

              if params[:type]
                replicate_content_groups, receive_content_groups = params[:secundary_groups], [params[:main_group]]
                replicate_content_offer, receive_content_offer   = secundary_offer, main_offer
              else
                replicate_content_groups, receive_content_groups = [params[:main_group]], params[:secundary_groups]
                replicate_content_offer, receive_content_offer   = main_offer, secundary_offer
              end

              ActiveRecord::Base.transaction do
                replicate_content_groups.each do |replicate_content_group_code|
                  replicate_content_group = get_offer_group(replicate_content_offer, replicate_content_group_code)
                  receive_content_groups.each do |receive_content_group_code|
                    receive_content_group = get_offer_group(receive_content_offer, receive_content_group_code)
                    replicate_content(replicate_content_group, receive_content_group, params[:type])
                  end
                end
              end
              secundary_offer.notify_editors_of_disabled_groups(Group.where(code: params[:secundary_groups])) if params[:type]

              { ok: :ok }
            end
          end # /

        end # merge

        # -- turmas
        #   -- periodo, tipo
        #   -- periodo, curso
        #   -- periodo, curso, disciplina
        desc "Todas as turmas por tipo de curso, semestre, curso, disciplina ou a propria turma"
        params do
          optional :semester, type: String
          optional :course_type_id, :course_id, :discipline_id, type: Integer
          optional :group_id, type: Integer
          exactly_one_of :group_id, :semester
          mutually_exclusive :group_id, :course_id
          mutually_exclusive :group_id, :discipline_id
          mutually_exclusive :group_id, :course_type_id
        end
        get "/" do # , rabl: "groups/index" do
          query = ["groups.status IS TRUE"]
          query << "semesters.name = :semester"                                 if params[:semester].present?
          query << "curriculum_units.curriculum_unit_type_id = :course_type_id" if params[:course_type_id].present?
          query << "offers.course_id = :course_id"                              if params[:course_id].present?
          query << "offers.curriculum_unit_id = :discipline_id"                 if params[:discipline_id].present?
          query << "groups.id = :group_id"                                      if params[:group_id].present?

          @groups = Group.joins(offer: [:semester, :curriculum_unit]).where(query.join(' AND '), params.slice(:course_type_id, :semester, :course_id, :discipline_id, :group_id))

          @groups.map{ |group|
            offer = group.offer
            { 
              id: group.id,
              code: group.code,
              offer_id: group.offer_id,
              start_date: offer.start_date,
              end_date: offer.end_date,
              course_id: offer.course_id,
              curriculum_unit_id: offer.curriculum_unit_id,
              semester_id: offer.semester_id,
              students: Allocation.joins(:profile).where("cast( profiles.types & '#{Profile_Type_Student}' as boolean )").where(allocation_tag_id: group.allocation_tag.related, status: Allocation_Activated).count
            }
          }
        end

      end # groups

      namespace :group do
        desc "Criação de turma"
        params do
          requires :code, type: String
          optional :offer_id, type: Integer#, values: -> { Offer.all.map(&:id) }
          optional :course_code, :curriculum_unit_code, :semester, type: String
          optional :activate, type: Boolean, default: false
          exactly_one_of :offer_id, :course_code
          exactly_one_of :offer_id, :curriculum_unit_code
          exactly_one_of :offer_id, :semester
        end
        post "/" do
          begin
            if params[:course_code].present?
              offer_id = Offer.where(course_id: Course.find_by_code(params[:course_code]).try(:id), curriculum_unit_id: CurriculumUnit.find_by_code(params[:curriculum_unit_code]).try(:id),
                semester_id: Semester.find_by_name(params[:semester]).try(:id)).first.try(:id)
              params.merge!({offer_id: offer_id})
            end
            if params[:activate]
              group = Group.where(group_params(params)).first_or_initialize
              group.status = true
              group.save!
            else
              group = Group.create! group_params(params)
            end
            {id: group.id}
          end
        end

        desc "Edição de turma"
        params do
          requires :id, type: Integer#, values: -> { Group.all.map(&:id) }
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
          end
        end
      end # group

    end # segment

  end
end
