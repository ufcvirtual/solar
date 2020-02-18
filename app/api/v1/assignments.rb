module V1
  class Assignments < Base

    guard_all!

    namespace :assignments do

      helpers do

        def verify_user_permission_on_assignments_and_set_obj(permission, controler) # permission = [:index, :create, ...]
          raise 'exam' if Exam.verify_blocking_content(current_user.id) || false
          @group      = Group.find(params[:group_id])
          @at = AllocationTag.find_by_group_id(@group.id)
          @group.allocation_tag.related
          @profile_id = current_user.profiles_with_access_on(permission, controler, @group.allocation_tag.related, true).first
          raise CanCan::AccessDenied if @profile_id.nil? || !(current_user.groups([@profile_id], Allocation_Activated).include?(@group))
        end

        def is_responsible(permission,  controler) 
          verify_user_permission_on_assignments_and_set_obj(permission, controler)

          raise  CanCan::AccessDenied unless current_user.id == params[:student_id].to_i || AllocationTag.find(@at.id).is_observer_or_responsible?(current_user.id)
        end

        def assignment_webconference_params
          ActionController::Parameters.new(params).require(:assignment_webconference).permit(:title, :initial_time, :duration, :is_recorded)
        end

      end
      segment do
        before do
          verify_user_permission_on_assignments_and_set_obj(:list, :assignments)
        end # befor

        desc "Listar todos trabalhos da turma", {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          requires :group_id, type: Integer
        end
        get "/" , rabl: 'assignments/list' do
          @is_student  = !@at.is_observer_or_responsible?(current_user.id)
          @assignments = Assignment.joins(:schedule, academic_allocations: :allocation_tag).where(allocation_tags: {id: @at.id})
        end
      end

      segment do
        before do
          is_responsible(:list, :assignments)
        end # befor

        desc "Listar todas as informações de trabalhos do aluno", {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          requires :assignment_id, type: Integer
          requires :group_id, type: Integer
        end
        get "/:assignment_id/participants" , rabl: 'assignments/index' do
          @assignment = Assignment.find(params[:assignment_id].to_i)
          @objects =  @assignment.type_assignment.to_i == Assignment_Type_Individual ? AllocationTag.get_participants(@at.id, { students: true }) : @assignment.groups_assignments(@at.id)
        end
      end

      segment do
        before do
          is_responsible(:list, :assignments)
        end # befor
        desc "Listar todas as informações de trabalhos dos alunos", {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        
        params do
          requires :student_id, type: Integer
          requires :group_id, type: Integer
        end
        get "/:student_id/all" , rabl: 'assignments/info' do
          @student = User.find(params[:student_id].to_i)
          ac = AcademicAllocation.where(allocation_tag_id: @at.id, academic_tool_type: 'Assignment')
          acus_indi = AcademicAllocationUser.where(user_id: @student.id).where(academic_allocation_id: ac.map(&:id))
          acus_groups = AcademicAllocationUser.where('group_assignment_id IS NOT NULL').where(academic_allocation_id: ac.map(&:id))
          @acus = acus_indi.concat(acus_groups)
        end
      end

      segment do
        before do
          verify_user_permission_on_assignments_and_set_obj(:show, :assignments)
        end
        desc "Enviar arquivo de trabalho", {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          requires :assignment_id, type: Integer
          requires :group_id, type: Integer
          requires :file, type: File
        end
        post "/file" do
          assignment = Assignment.find(params[:assignment_id])
          aloc = AcademicAllocation.where(allocation_tag_id: @at.id, academic_tool_id: params[:assignment_id], academic_tool_type: 'Assignment').first
          group_id = assignment.type_assignment.to_i == Assignment_Type_Individual ? nil : GroupAssignment.by_user_id(current_user.id, aloc.id).id
          acu = AcademicAllocationUser.find_or_create_one(aloc.id, @at.id, current_user.id, group_id, true, nil)

          af = AssignmentFile.new({academic_allocation_user_id: acu.id, attachment: ActionDispatch::Http::UploadedFile.new(params[:file])})
          af.user = current_user
          af.api = true

          if af.save!
            { id: af.id }
          else
            raise af.errors.full_messages.join(', ')
          end
        end

        desc "Remover arquivo enviado", {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          requires :id, type: Integer
          requires :group_id, type: Integer
        end
        delete "/file/:id" do
          assignment_file = AssignmentFile.find(params[:id].to_i)
          raise CanCan::AccessDenied if (assignment_file.user_id != current_user.id)
          assignment_file.api = true
          assignment_file.destroy

          {ok: :ok}
        end
      end
      segment do
        before do
          verify_user_permission_on_assignments_and_set_obj(:create, :assignment_webconferences)
        end
        desc "Agendar webconference de trabalho", {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          requires :group_id, type: Integer
          requires :assignment_id, type: Integer
          requires :assignment_webconference, type: Hash do
            requires :title, type: String
            requires :initial_time, type: String
            requires :duration, type: String
            requires :is_recorded, type: Boolean, default: false
          end
        end
        post "/webconference" do
          assignment = Assignment.find(params[:assignment_id])
          aloc = AcademicAllocation.where(allocation_tag_id: @at.id, academic_tool_id: params[:assignment_id], academic_tool_type: 'Assignment').first
          group_id = assignment.type_assignment.to_i == Assignment_Type_Individual ? nil : GroupAssignment.by_user_id(current_user.id, aloc.id).id
          acu = AcademicAllocationUser.find_or_create_one(aloc.id, @at.id, current_user.id, group_id, true, nil)
     
          awf = AssignmentWebconference.new(assignment_webconference_params)
          awf.academic_allocation_user_id = acu.id
          awf.api = true

          if awf.save
            { id: awf.id }
          else
            raise awf.errors.full_messages.join(', ')
          end
        end

        desc "Remover webconference agendada", {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          requires :id, type: Integer
          requires :group_id, type: Integer
        end
        delete "/webconference/:id" do
          awf = AssignmentWebconference.find(params[:id].to_i)
          raise CanCan::AccessDenied unless awf.owner(current_user.id)
          awf.api = true
          awf.destroy

          {ok: :ok}
        end
      end
    end

  end
end
