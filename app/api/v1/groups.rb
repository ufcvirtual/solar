module V1
  class Groups < Base

    segment do

      before { guard! }

      namespace :curriculum_units do

        desc "Turmas de uma UC do usuario"
        params do
         requires :id, type: Integer #, values: -> { CurriculumUnit.all.map(&:id) } }
         optional :profiles_ids, type: Array
        end
        get ":id/groups", rabl: "groups/list" do
          profiles_ids   = current_user.profiles_with_access_on('show', 'curriculum_units', nil, true)
          profiles_ids   = (profiles_ids & params[:profiles_ids]) if params[:profiles_ids]

          user_groups    = current_user.groups(profiles_ids, Allocation_Activated).map(&:id)
          current_offers = Offer.currents({verify_end_date: true, profiles: profiles_ids, user_id: current_user.id})
          @groups = Group.joins(:offer).where(id: user_groups, offer_id: current_offers).where("offers.curriculum_unit_id = ?", params[:id]) rescue []
        end

      end # curriculum_units

      before { guard! }

      namespace :user do

        desc "Turmas de um usuario"
        params do
          optional :semester, type: String
          optional :curriculum_unit_type_id, :course_id, :curriculum_unit_id, type: Integer
          optional :profiles_ids, type: Array
        end
        get :groups, rabl: "groups/list_by_user" do
          profiles_ids   = current_user.profiles_with_access_on('show', 'curriculum_units', nil, true)
          profiles_ids   = (profiles_ids & params[:profiles_ids]) if params[:profiles_ids]
          # only returns groups with access to curriculum_unit
          user_groups    = current_user.groups(profiles_ids, Allocation_Activated)

          offers = if params[:semester].present?
            Offer.joins(:semester).where(params.slice(:curriculum_unit_type_id, :course_id, :curriculum_unit_id)).where(semesters: { name: params[:semester] }).pluck(:id)
          else
            Offer.currents({ verify_end_date: true, profiles: profiles_ids, user_id: current_user.id }.merge!(params.slice(:curriculum_unit_type_id, :course_id, :curriculum_unit_id)))
          end

          @groups = user_groups.joins(offer: [:semester, :course, curriculum_unit: :curriculum_unit_type])
                               .joins('JOIN allocation_tags ON allocation_tags.group_id = groups.id OR allocation_tags.offer_id = offers.id OR allocation_tags.course_id = courses.id OR allocation_tags.curriculum_unit_id = curriculum_units.id OR allocation_tags.curriculum_unit_type_id = curriculum_unit_types.id')
                               .joins("JOIN allocations ON allocations.allocation_tag_id = allocation_tags.id AND allocations.user_id = #{current_user.id}")
                               .where(offer_id: offers)
                               .select("groups.id, groups.code, semesters.name AS semester_name, curriculum_units.code AS uc_code, curriculum_units.name AS uc_name, courses.code AS course_code, courses.name AS course_name, curriculum_unit_types.description AS type, replace(translate(array_agg(distinct allocations.profile_id)::text,'{}', ''),'\"', '') AS profiles")
                               .group('groups.id, semesters.id, courses.id, offers.id, curriculum_units.id, curriculum_unit_types.id') rescue []
        end

      end # user

    end # segment

    segment do

      before { verify_ip_access_and_guard! }

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

        desc "Todas as turmas por semestre, tipo de curso, curso, disciplina e status da turma"
        params do
          requires :semester, type: String
          optional :curriculum_unit_type_id, default: 2, type: Integer
          optional :course_id, :curriculum_unit_id, type: Integer
          optional :course_code, :curriculum_unit_code, type: String
          optional :only_active, default: false, type: Boolean
          mutually_exclusive :course_code, :course_id
          mutually_exclusive :curriculum_unit_code, :curriculum_unit_id
        end
        get :all , rabl: "groups/all" do
          query =  ["semesters.name = :semester"]
          query << "curriculum_units.curriculum_unit_type_id = :curriculum_unit_type_id"
          query << if params[:course_id].present?
           "(courses.id = :course_id)"
          elsif params[:course_code].present?
            "(courses.code = :course_code)"
          end
          query << if params[:curriculum_unit_id].present?
           "(curriculum_units.id = :curriculum_unit_id)"
          elsif params[:curriculum_unit_code].present?
            "(curriculum_units.code = :curriculum_unit_code)"
          end

          @offers = Offer.joins(:semester, :curriculum_unit, :course).where(query.compact.join(' AND '), params.slice(:semester, :curriculum_unit_type_id, :course_id, :course_code, :curriculum_unit_code, :curriculum_unit_id))

          @groups = (params[:only_active] ? :active_groups : :groups)
        end

      end # groups

      namespace :group do

        segment do
          after_validation do
            if params[:course_code].present?
              offer_id = Offer.where(course_id: Course.find_by_code(params[:course_code]).try(:id), curriculum_unit_id: CurriculumUnit.find_by_code(params[:curriculum_unit_code]).try(:id),
                semester_id: Semester.find_by_name(params[:semester]).try(:id)).first.try(:id)
              params.merge!({offer_id: offer_id})
            end
          end

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

          desc "Remove turma"
           params do
            optional :code, type: String
            optional :id, type: Integer
            optional :offer_id, type: Integer
            optional :course_code, :curriculum_unit_code, :semester, type: String
            exactly_one_of :id, :offer_id, :course_code
            exactly_one_of :id, :offer_id, :curriculum_unit_code
            exactly_one_of :id, :offer_id, :semester
            exactly_one_of :id, :code
          end
          delete "/" do
            begin
              unless params[:id].blank?
                group = Group.find(params[:id])
              else
                group = Group.where(offer_id: group_params(params)[:offer_id]).where("lower(code) = ?", group_params(params)[:code].downcase).first
              end

              unless group.blank?
                begin
                  group.destroy
                rescue
                  group.status = false
                  group.save!

                  group.offer.notify_editors_of_disabled_groups([group])
                end
              end
              {ok: :ok}
            end
          end

        end #segment

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
            group.offer.notify_editors_of_disabled_groups([group]) if params[:status].present? && !(params[:status])

            {ok: :ok}
          end
        end

        desc 'Recuperação de dados dos alunos com relacao a turma'
        params do
          requires :group_code, :semester, :course_code, :curriculum_unit_code, type: String
          optional :curriculum_unit_type_id, default: 2
        end
        get :students_info, rabl: 'groups/students_info' do
          begin
            group = Group.joins(offer: [:semester, :course, :curriculum_unit])
                         .where(code: params[:group_code],
                            semesters: { name: params[:semester] },
                            curriculum_units: { code: params[:curriculum_unit_code], curriculum_unit_type_id: params[:curriculum_unit_type_id] },
                            courses: { code: params[:course_code] }
                         ).first

            raise ActiveRecord::RecordNotFound if group.nil?

            @allocation_tag_id = group.allocation_tag.id
            get_group_students_info(@allocation_tag_id, group)
          end
        end # students_info

        desc 'Recuperação de dados da turma'
        params do
          requires :group_code, :semester, :course_code, :curriculum_unit_code, type: String
          optional :curriculum_unit_type_id, default: 2
        end
        get :info, rabl: 'groups/info' do
          begin

            group = Group.joins(offer: [:semester, :course, :curriculum_unit])
                         .where(code: params[:group_code],
                            semesters: { name: params[:semester] },
                            curriculum_units: { code: params[:curriculum_unit_code], curriculum_unit_type_id: params[:curriculum_unit_type_id] },
                            courses: { code: params[:course_code] }
                         ).first

            raise ActiveRecord::RecordNotFound if group.nil?
            get_group_info(group)
            raise ActiveRecord::RecordNotFound if @group.blank?
            @group = @group.first
          end
        end # info

        desc 'Recuperação de dados do responsavel com relacao a turma'
        params do
          requires :group_code, :semester, :course_code, :curriculum_unit_code, :cpf, type: String
          optional :curriculum_unit_type_id, default: 2
        end
        get :responsible_info, rabl: 'groups/responsible_info' do
          begin
            user  = User.find_by_cpf(params[:cpf])
            raise ActiveRecord::RecordNotFound if user.nil?

            group = Group.joins(offer: [:semester, :course, :curriculum_unit])
                         .where(code: params[:group_code],
                            semesters: { name: params[:semester] },
                            curriculum_units: { code: params[:curriculum_unit_code], curriculum_unit_type_id: params[:curriculum_unit_type_id] },
                            courses: { code: params[:course_code] }
                         ).first
            raise ActiveRecord::RecordNotFound if group.nil?

            @allocation_tag_id = group.allocation_tag.id
            get_group_responsible_info(user.id, @allocation_tag_id, group)
          end
        end # students_info

      end # group

    end # segment

  end
end
