module V1
  class Webconferences < Base

    guard_all!

    namespace :webconferences do

      before do
        @group_id = params[:group_id]
        @at = AllocationTag.find_by_group_id(@group_id)
      end

      helpers do
        def verify_permission(method, at)
          permission = current_user.profiles_with_access_on(method, :webconferences, [at], true)

          raise CanCan::AccessDenied if permission.empty?
        end
      end

      ## api/v1/webconferences/1/
      params { requires :group_id, type: Integer, desc: 'ID da turma' }
      get ":group_id", rabl: 'webconferences/index' do
        if Exam.verify_blocking_content(current_user.id)
          error!({ error: :open_exam }, 401)
        else
          verify_permission(:index, @at.related)
          @is_student = current_user.is_student?([@at.id])
          @webconferences = Webconference.all_by_allocation_tags(@at.related(upper: true), {asc: true}, current_user.id)
          User.current = current_user
        end
      end # get

      desc "Retorna link para acesso a Webconferencia"
      params do
        requires :group_id, type: Integer, desc: 'ID da turma'
        requires :id, type: Integer, desc: 'ID da webconferência'
      end
      get ":group_id/access/:id", rabl: 'webconferences/access_url' do
        if Exam.verify_blocking_content(current_user.id)
          error!({ error: :open_exam }, 401)
        else
          begin
            verify_permission(:interact, @at.related)
            webconference = Webconference.find(params[:id])

            raise 'closed' unless webconference.on_going?
            raise 'offline' unless webconference.bbb_online?

            @url = webconference.link_to_join(current_user, @at.id, true)
            URI.parse(@url).path

            ac_id = (webconference.academic_allocations.size == 1 ? webconference.academic_allocations.first.id : webconference.academic_allocations.where(allocation_tag_id: @at.id).first.id)

            acu = AcademicAllocationUser.find_or_create_one(ac_id, @at.id, current_user.id, nil, true)
            LogAction.access_webconference(academic_allocation_id: ac_id, academic_allocation_user_id: acu.try(:id), user_id: current_user.id, ip: request.headers['Solar'], allocation_tag_id: @at.id, description: webconference.attributes) if @at.is_student_or_responsible?(current_user.id)
          end
        end
      end # get

      desc "Retorna links para acesso as gravacoes caso existam"
      params do
        requires :group_id, type: Integer, desc: 'ID da turma'
        requires :id, type: Integer, desc: 'ID da webconferência'
      end
      get ":group_id/recordings/:id" do
        if Exam.verify_blocking_content(current_user.id)
          error!({ error: :open_exam }, 401)
        else
          begin
            verify_permission(:index, @at.related)
            raise CanCan::AccessDenied if current_user.is_researcher?(AllocationTag.where(id: @at.id).map(&:related).flatten.uniq)

            webconference = Webconference.find(params[:id])

            raise 'not_started' unless webconference.started?
            raise 'on_going' if webconference.on_going?
            raise 'offline' unless webconference.bbb_online?
            raise 'still_processing' unless webconference.is_over?

            return webconference.get_all_recordings_urls(@at.id)
          end
        end
      end # get

    end # namespace
  end
end