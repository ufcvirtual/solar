module V1
  class Logs < Base

    guard_all!

    namespace :logs do

      helpers do
        def verify_permission(method)
          permission = current_user.profiles_with_access_on(method, :logs, nil, true)
          raise CanCan::AccessDenied if permission.empty?
        end
      end

      ## api/v1/logs/
      params do
        requires :semester, type: String
        requires :course_id, :curriculum_unit_id, type: Integer
      end
      get :index, rabl: 'logs/index' do

        verify_permission(:index)
        semester = Semester.where(name: params[:semester]).first
        groups = Group.joins(:offer).where(offers: {course_id: params[:course_id], curriculum_unit_id: params[:curriculum_unit_id], semester_id: semester.id}, status: true)

        @ats = groups.map(&:allocation_tag).map(&:id).flatten.uniq
        @ats << groups.first.offer.allocation_tag.related({upper: true})
        
        @logs = LogAccess.find_by_sql <<-SQL
          SELECT DISTINCT allocations.user_id AS student, allocations.allocation_tag_id
          FROM allocations, profiles
          WHERE profiles.id = allocations.profile_id AND cast(profiles.types & #{Profile_Type_Student} as boolean) AND 
          allocations.status = #{Allocation_Activated} AND allocations.allocation_tag_id IN (#{@ats.join(',')});
        SQL
        arr_student = @logs.map(&:student).flatten.uniq
        #APAGA E CRIA TABELAS TEMPORARIAS
        LogAccess.drop_and_create_table_temporary_logs_navigation_sub(@ats.flatten.uniq, arr_student)
        LogAccess.drop_and_create_table_temporary_logs_chat_messages(@ats.flatten.uniq, arr_student)   
        LogAccess.drop_and_create_table_temporary_logs_navigation(@ats.flatten.uniq, arr_student)  
        #LogAccess.drop_and_create_table_temporary_logs_access(@ats, arr_student)
        LogAccess.drop_and_create_table_temporary_logs_comments(@ats.flatten.uniq, arr_student) 
      end # get

    end # namespace
  end
end