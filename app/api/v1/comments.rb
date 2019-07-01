module V1
  class Comments < Base

    guard_all!

    namespace :comments do

      helpers do
        def get_ac_tool
          @ac = AcademicAllocation.where(academic_tool_type: params[:tool_type], academic_tool_id: params[:tool_id], allocation_tag_id: @ats).first
        end

        def verify_access
          is_observer_or_responsible = AllocationTag.find(@ats.first).is_observer_or_responsible?(current_user.id)

          if params[:tool_type] == 'Assignment'
            raise CanCan::AccessDenied unless Assignment.owned_by_user?(current_user.id, { student_id: params[:student_id], group: params[:group_assignment_id] }) || is_observer_or_responsible
          else
            raise CanCan::AccessDenied unless params[:student_id] == current_user.id || is_observer_or_responsible
          end
        end
      end

      after_validation do
        # if tool allow creation at offer, recover all related ats
        @ats = params[:tool_type].constantize.const_defined?("OFFER_PERMISSION") ?
        RelatedTaggable.related(group_id: params[:group_id]) : [AllocationTag.find_by_group_id(params[:group_id])]

        get_ac_tool
        verify_access
      end

      ## api/v1/comments/:student_id
      desc "Lista de comentários por atividade", {
        headers: {
          "Authorization" => {
            description: "Token",
            required: true
          }
        }
      }
      params do
        requires :group_id, type: Integer, desc: 'ID da turma'
        optional :student_id, type: Integer, desc: 'ID do aluno'
        optional :group_assignment_id, type: Integer, desc: 'ID do grupo'
        optional :academic_allocation_id, type: Integer, desc: 'ID da AC'
        optional :tool_type, type: String, desc: 'Tipo da ferramenta'
        optional :tool_id, type: Integer, desc: 'ID da ferramenta'
        exactly_one_of :student_id, :group_assignment_id
        at_least_one_of :tool_id, :academic_allocation_id
        all_or_none_of :tool_id, :tool_type
      end
      get '/', rabl: "comments/list" do
        acu = AcademicAllocationUser.where(academic_allocation_id: @ac.id, user_id: params[:student_id], group_assignment_id: params[:group_assignment_id]).first

        @comments = acu.blank? ? [] : acu.comments
      end # get

    end # namespace
  end
end
