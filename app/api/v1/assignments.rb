module V1
  class Assignments < Base

    guard_all!

    namespace :assignments do

      helpers do

        def assignment_webconference_params
          ActionController::Parameters.new(params).require(:assignment_webconference).permit(:title, :initial_time, :duration, :is_recorded)
        end

      end
      
      desc "Listar todos trabalhos da turma"
      params do
        requires :allocation_tag_id, type: Integer
      end
      get "/" , rabl: 'assignments/list' do
        @assignments = Assignment.joins(:schedule, academic_allocations: :allocation_tag).where(allocation_tags: {id: params[:allocation_tag_id].to_i})
      end

      desc "Listar todas as informações de trabalhos do aluno"
      params do
        requires :student_id, type: Integer
        requires :allocation_tag_id, type: Integer
      end
      get "/:student_id/all" , rabl: 'assignments/info' do
        @student = User.find(params[:student_id].to_i)
        ac = AcademicAllocation.where(allocation_tag_id: params[:allocation_tag_id].to_i, academic_tool_type: 'Assignment')
        @acus = AcademicAllocationUser.where("(user_id = ? OR group_assignment_id IS NOT NULL)", params[:student_id].to_i).where(academic_allocation_id: ac.map(&:id))
        #p acus_groups = AcademicAllocationUser.where('group_assignment_id IS NOT NULL').where(academic_allocation_id: ac.map(&:id))
        #@acus = acus_indi.to_a.concat(acus_groups.to_a)
      end

      desc "Enviar arquivo de trabalho"
      post "/file" do
        al = AcademicAllocation.where(allocation_tag_id: params[:allocation_tag_id].to_i).where(academic_tool_id: params[:assignment_id]).first
        acu = AcademicAllocationUser.where(academic_allocation_id: al.id).first

        af = AssignmentFile.new({academic_allocation_user_id: acu.id, attachment: ActionDispatch::Http::UploadedFile.new(params[:file])})
        af.user = User.find(params[:user_id].to_i)
        af.save!
        
        {ok: :ok}
      end
      
      desc "Remover arquivo enviado"
      params do
        requires :id, type: Integer
      end
      delete "/file/:id" do
        assignment_file = AssignmentFile.find(params[:id].to_i)
        assignment_file.destroy
        
        {ok: :ok}
      end

      desc "Agendar webconference de trabalho"
      params do
        requires :assignment_webconference, type: Hash do
          requires :title, type: String
          requires :initial_time, type: String
          requires :duration, type: String
          requires :is_recorded, type: Boolean, default: false
        end
      end
      post "/webconference" do
        al = AcademicAllocation.where(allocation_tag_id: params[:allocation_tag_id].to_i).where(academic_tool_id: params[:assignment_id]).first
        acu = AcademicAllocationUser.where(academic_allocation_id: al.id).first

        awf = AssignmentWebconference.new(assignment_webconference_params)
        awf.academic_allocation_user_id = acu.id
        awf.api_call = true
        
        if awf.save
          { id: awf.id }
        else
          raise awf.errors.full_messages
        end
      end

      desc "Remover webconference agendada"
      params do
        requires :id, type: Integer
      end
      delete "/webconference/:id" do
        awf = AssignmentWebconference.find(params[:id].to_i)
        awf.destroy
        
        {ok: :ok}
      end

    end

  end
end