module V1
  class Scores < Base

    namespace :groups do

      before do
        begin
          @at  = AllocationTag.find_by_group_id(params[:id])
          @ats = RelatedTaggable.related(group_id: params[:id])
          raise 'error' if @at.blank?
        rescue
          raise 'group does not exist'
        end
      end

      ## api/v1/groups/1/scores/info
      desc "Lista de atividades", {
        headers: {
          "Authorization" => {
            description: "Token",
            required: true
          }
        }
      }
      params do
          requires :id, type: Integer, desc: 'ID da turma'
          optional :tool, type: Array[String], default: 'all'#, values: ['all', 'discussions', 'assignments', 'chat_rooms', 'webconferences', 'exams', 'schedule_events']
          optional :list, type: String, default: 'all'#, values: ['all', 'evaluative', 'frequency', 'not_evaluative']
          optional :user_id, type: Integer
        end
      get ':id/scores/info' do
        begin
          raise 'blank user_id' unless params.include?(:user_id)
          authorize! :index, Score, on: [@at.id]
          user = User.find(params[:user_id])
        rescue
          authorize! :info, Score, on: [@at.id]
          user = current_user
        end

        is_student = user.is_student?([@at.id])

        raise "user #{current_user.id} can't access user #{user.id} (student: #{is_student})" if !is_student && current_user.profiles_with_access_on("responsibles", "scores", @ats).empty?

        history_access, public_files, count_access = Score.informations(user.id, @at, related: @ats)

        tools = ((params[:tool].include?('all') || params[:tool].empty?) ? 'all' : params[:tool])

        tools = Score.list_tool(user.id, @at.id, tools, (params[:list] == 'evaluative'), (params[:list] == 'frequency'), (params[:list] == 'all'))
        tools = tools.group_by { |t| t['academic_tool_type'] }

        if is_student
          assignments = tools['Assignment'].as_json || []
          assignments.each do |assignment_hash|
            acu = AcademicAllocationUser.where(group_assignment_id: assignment_hash['group_id'], user_id: assignment_hash['user_id'], academic_allocation_id: assignment_hash['id']).first
            assignment_hash.merge!(comments: (acu.comments.map{ |comment| { user_id: comment.user_id, user_name: comment.user.name, comment: comment.comment, created_at: comment.updated_at }} rescue []))
          end
        else
        end

        {
          assignments: assignments || [],
          discussions: tools['Discussion'].as_json || [],
          webconferences: tools['Webconference'].as_json || [],
          chat_rooms: (is_student ? (tools['ChatRoom'].as_json || []) : nil),
          schedule_events: (is_student ? (tools['ScheduleEvent'].as_json || []) : nil),
          exams: (is_student ? (tools['Exam'].as_json || []) : nil),
          history_access: history_access.map { |h| { created_at: h.created_at } },
          count_access: count_access,
          public_files: public_files.size
        }

      end # get

      ## api/v1/groups/1/scores/
      desc "Lista das atividades de alunos e responsáveis", {
        headers: {
          "Authorization" => {
            description: "Token",
            required: true
          }
        }
      }
      params do
          requires :id, type: Integer, desc: 'ID da turma'
          optional :list, type: String, default: 'all'#, values: ['general_view', 'all', 'evaluative', 'frequency', 'not_evaluative']
        end
      get ':id/scores' do
        authorize! :index, Score, on: [@at.id]

        if params[:list] == 'general_view'
          users = AllocationTag.get_participants(@at.id, { students: true }, true)
          users = users.group_by{|user| user["name"]}
        else
          users = Score.evaluative_frequency(@ats.join(','), params[:list])
          users = users.group_by{|user| user["user_name"]}
        end

        tools = ( @ats.empty? ? [] : EvaluativeTool.count_tools(@ats.join(',')) )

        {
          students: users.sort,
          count_tools: tools,
          responsibles: (current_user.profiles_with_access_on("responsibles", "scores", @ats).any? ? AllocationTag.get_participants(@at.id, { responsibles: true, profiles: Profile.with_access_on("create", "posts").join(",") }, true) : [])
        }

      end # get

      desc "Sumário dos alunos", {
        headers: {
          "Authorization" => {
            description: "Token",
            required: true
          }
        }
      }
      params do
          requires :id, type: Integer, desc: 'ID da turma'
          optional :list, type: String, default: 'all'#, values: ['general_view', 'all', 'evaluative', 'frequency', 'not_evaluative']
        end
      get ':id/scores/summary', rabl: 'scores/summary' do
        authorize! :index, Score, on: [@at.id]

        @group = Group.find(params[:id])

        @users = AllocationTag.get_participants(@at.id, { students: true }, true)
        @wh = AllocationTag.find(@at.id).get_curriculum_unit.try(:working_hours)
      end

      segment do

        before do
          begin
            authorize! :index, Score, on: [@at.id]
            @user_id = params[:user_id]
          rescue
            authorize! :info, Score, on: [@at.id]
            @user_id = current_user.id
          end
        end

        desc "Sumário do aluno em fórum", {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
            requires :id, type: Integer, desc: 'ID da Turma'
            requires :discussion_id, type: Integer, desc: 'ID do Fórum'
            requires :user_id, type: Integer, desc: 'ID da Aluno'
          end
        get ':id/scores/discussion/:discussion_id/info', rabl: 'scores/discussion' do

          posts = Post.joins(:academic_allocation).where(academic_allocations: { allocation_tag_id: @at.id, academic_tool_id: params[:discussion_id], academic_tool_type: 'Discussion' }, user_id: @user_id, draft: false).order('updated_at DESC')

          discussion = Discussion.find(params[:discussion_id])
          academic_allocation = discussion.academic_allocations.where(allocation_tag_id: @at.id).first
          all_user = AcademicAllocationUser.find_one(academic_allocation.id, @user_id, nil, false)

          Struct.new('PostsScores',:posts, :all_user)
          @posts_scores = Struct::PostsScores.new(posts, all_user)
        end

        desc "Sumário do aluno em trabalho", {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
            requires :id, type: Integer, desc: 'ID da Turma'
            requires :assignment_id, type: Integer, desc: 'ID do Trabalho'
            requires :user_id, type: Integer, desc: 'ID da Aluno'
          end
        get ':id/scores/assignment/:assignment_id/info', rabl: 'scores/assignment' do
          authorize! :index, Score, on: [@at.id]
          ac = AcademicAllocation.where(academic_tool_id: params[:assignment_id], allocation_tag_id: @at.id, academic_tool_type: 'Assignment').first
          @acu = AcademicAllocationUser.where(academic_allocation_id: ac.id).where(user_id: params[:user_id]).first
        end

        desc "Sumário do aluno em webconferência", {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
            requires :id, type: Integer, desc: 'ID da Turma'
            requires :webconference_id, type: Integer, desc: 'ID da Webconferência'
            requires :user_id, type: Integer, desc: 'ID da Aluno'
          end
        get ':id/scores/webconference/:webconference_id/info', rabl: 'scores/webconference' do
          authorize! :index, Score, on: [@at.id]
          webconference = Webconference.find(params[:webconference_id])

          academic_allocations_ids = (webconference.shared_between_groups ? webconference.academic_allocations.map(&:id) : webconference.academic_allocations.where(allocation_tag_id: @at.id).first.try(:id))
          ats = AllocationTag.where(id: @at.id).map(&:related)
          logs = webconference.get_access(academic_allocations_ids, ats, {user_id: params[:user_id]})
          acs = AcademicAllocation.where(id: academic_allocations_ids)
          academic_allocation = acs.where(allocation_tag_id: @at.id).first
          acu = AcademicAllocationUser.find_one(academic_allocation.id, params[:user_id], nil, false)

          Struct.new('WebScores',:logs, :acu)
          @webconference_scores = Struct::WebScores.new(logs, acu)
        end

        desc "Sumário do aluno em chat", {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          requires :id, type: Integer, desc: 'ID da Turma'
          requires :chat_id, type: Integer, desc: 'ID do Chat'
          requires :user_id, type: Integer, desc: 'ID da Aluno'
        end
        get ':id/scores/chat/:chat_id/info', rabl: 'scores/chat' do
          authorize! :index, Score, on: [@at.id]
          chat_room = ChatRoom.find(params[:chat_id])
          messages = chat_room.get_messages(@at.id, {user_id: params[:user_id]} )
          academic_allocation = chat_room.academic_allocations.where(allocation_tag_id: @at.id).first
          acu = AcademicAllocationUser.find_one(academic_allocation.id, params[:user_id],nil, false)

          Struct.new('ChatScores',:messages, :acu)
          @chat_scores = Struct::ChatScores.new(messages, acu)
        end

        desc "Cadastra novo comentário para aluno.", {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        params do
          requires :id, type: Integer, desc: 'ID da Turma'
          requires :academic_allocation_user_id, type: Integer, desc: 'ID da AcademicAllocationUser'
          requires :comment, type: String
        end
        post ':id/scores/comment/:academic_allocation_user_id' do
          authorize! :index, Score, on: [@at.id]
          comment = Comment.new(academic_allocation_user_id: params[:academic_allocation_user_id], comment: params[:comment], user_id: current_user)
          comment.api = true
          comment.save!

          {ok: 'ok'}
        end
      end #segment

    end # namespace

  end
end
