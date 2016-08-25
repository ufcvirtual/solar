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
      params do
          requires :id, type: Integer, desc: 'ID da turma'
          optional :tool, type: Array[String], default: 'all', values: ['all', 'discussions', 'assignments', 'chat_rooms', 'webconferences', 'exams', 'schedule_events']
          optional :list, type: String, default: 'all', values: ['all', 'evaluative', 'frequency', 'not_evaluative']
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
            assignment_hash.merge!(comments: (acu.assignment_comments.map{ |comment| { user_id: comment.user_id, user_name: comment.user.name, comment: comment.comment, created_at: comment.updated_at }} rescue []))
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

      before do
        begin
          @at  = AllocationTag.find_by_group_id(params[:id])
          @ats = RelatedTaggable.related(group_id: params[:id])
          raise 'error' if @at.blank?
        rescue
          raise 'group does not exist'
        end
      end

      ## api/v1/groups/1/scores/
      params do
          requires :id, type: Integer, desc: 'ID da turma'
          optional :list, type: String, default: 'all', values: ['general_view', 'all', 'evaluative', 'frequency', 'not_evaluative']
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
          students: users,
          count_tools: tools,
          responsibles: (current_user.profiles_with_access_on("responsibles", "scores", @ats).any? ? AllocationTag.get_participants(@at.id, { responsibles: true, profiles: Profile.with_access_on("create", "posts").join(",") }, true) : [])
        }

      end # get

    end # namespace

  end
end
