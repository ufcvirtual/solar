module V1
  class Logs < Base

    guard_all!

    namespace :logs do

      helpers do
        def verify_permission(method, ats=nil)
          permission = current_user.profiles_with_access_on(method, :logs, ats, true, false, true)

          raise CanCan::AccessDenied if permission.empty?
        end
      end

      # DO NOT UNCOMMENT IN PRODUCTION
      # # api/v1/logs/
      # params do
      #   requires :semester, type: String
      #   requires :course_code, :curriculum_unit_code, type: String
      # end
      # get '', rabl: 'logs/index' do

      #   semester = Semester.where(name: params[:semester]).first
      #   groups = Group.joins(offer: [:course, :curriculum_unit]).where(offers: {semester_id: semester.id}, courses: {code: params[:course_code]}, curriculum_units: {code: params[:curriculum_unit_code], curriculum_unit_type_id: 2}, status: true)

      #   @ats = groups.map(&:allocation_tag).map(&:id).flatten.uniq
      #   @ats << groups.first.offer.allocation_tag.related({upper: true})
      #   verify_permission(:index, @ats)

      #   @logs = LogAccess.find_by_sql <<-SQL
      #     SELECT DISTINCT allocations.user_id AS student, allocations.allocation_tag_id
      #     FROM allocations, profiles
      #     WHERE profiles.id = allocations.profile_id AND cast(profiles.types & #{Profile_Type_Student} as boolean) AND
      #     allocations.status = #{Allocation_Activated} AND allocations.allocation_tag_id IN (#{@ats.join(',')});
      #   SQL

      #   arr_student = @logs.map(&:student).flatten.uniq

      #   #APAGA E CRIA TABELAS TEMPORARIAS
      #   LogAccess.drop_and_create_table_temporary_logs_navigation_sub(@ats.flatten.uniq, arr_student)
      #   LogAccess.drop_and_create_table_temporary_logs_chat_messages(@ats.flatten.uniq, arr_student)
      #   LogAccess.drop_and_create_table_temporary_logs_navigation(@ats.flatten.uniq, arr_student)
      #   #LogAccess.drop_and_create_table_temporary_logs_access(@ats, arr_student)
      #   LogAccess.drop_and_create_table_temporary_logs_comments(@ats.flatten.uniq, arr_student)
      # end # get

      # # api/v1/logs/students
      # params do
      #   requires :semester, type: String
      #   requires :course_code, :curriculum_unit_code, type: String
      #   optional :group_name
      # end
      # get :students do

      #   semester = Semester.where(name: params[:semester]).first
      #   query = {offers: {semester_id: semester.id}, courses: {code: params[:course_code]}, curriculum_units: {code: params[:curriculum_unit_code], curriculum_unit_type_id: 2}, status: true}
      #   query.merge!({name: params[:group_name]}) unless params[:group_name].blank?
      #   groups = Group.joins(offer: [:course, :curriculum_unit]).where(query)

      #   @ats = groups.map(&:allocation_tag).map(&:id).flatten.uniq
      #   @ats << groups.first.offer.allocation_tag.related({upper: true})
      #   verify_permission(:index, @ats)

      #   {students: Allocation.joins(:profile).where(status: Allocation_Activated, allocation_tag_id: @ats).where("cast(profiles.types & #{Profile_Type_Student} as boolean)").pluck(:user_id).uniq}
      # end # get

      # # api/v1/logs/
      # params do
      #   requires :student_id, type: Integer
      #   optional :semester, type: String
      # end
      # get "students/:student_id", rabl: 'logs/index' do

      #   semester = Semester.where(name: params[:semester]).first
      #   user = User.find(params[:student_id])
      #   query = params[:semester].blank? ? '' : {allocation_tag_id: semester.offers.map(&:allocation_tag).map(&:related).flatten.uniq}

      #   @ats = user.allocations.joins(:profile).where(status: Allocation_Activated).where(query).where("cast(profiles.types & #{Profile_Type_Student} as boolean)").map(&:allocation_tag).map(&:related).flatten.uniq

      #   verify_permission(:index, @ats)

      #   @logs = LogAccess.find_by_sql <<-SQL
      #     SELECT DISTINCT allocations.user_id AS student, allocations.allocation_tag_id
      #     FROM allocations, profiles
      #     WHERE profiles.id = allocations.profile_id AND cast(profiles.types & #{Profile_Type_Student} as boolean) AND
      #     allocations.status = #{Allocation_Activated} AND allocations.allocation_tag_id IN (#{@ats.join(',')}) AND
      #     allocations.user_id = #{params[:student_id]};
      #   SQL

      #   #APAGA E CRIA TABELAS TEMPORARIAS
      #   LogAccess.drop_and_create_table_temporary_logs_navigation_sub(@ats.uniq, [params[:student_id]])
      #   LogAccess.drop_and_create_table_temporary_logs_chat_messages(@ats.uniq, [params[:student_id]])
      #   LogAccess.drop_and_create_table_temporary_logs_navigation(@ats.uniq, [params[:student_id]])
      #   #LogAccess.drop_and_create_table_temporary_logs_access(@ats, [params[:student_id]])
      #   LogAccess.drop_and_create_table_temporary_logs_comments(@ats.uniq, [params[:student_id]])
      # end # get


      get "user/:id", rabl: "users/show" do
        user = User.find(params[:id])
        courses = (YAML::load(File.open('config/global.yml'))[Rails.env.to_s]['uab_courses'] rescue nil)

        unless courses.blank?
          courses_ids = Course.where(code: courses.split(',')).pluck(:id)
          allocations = Allocation.find_by_sql <<-SQL
            SELECT allocations.id FROM allocations
              LEFT JOIN allocation_tags ON allocations.allocation_tag_id = allocation_tags.id
              LEFT JOIN groups ON groups.id = allocation_tags.group_id
              LEFT JOIN offers ON groups.offer_id = offers.id
              WHERE allocations.user_id = #{user.id}
              AND allocations.status = 1
              AND allocations.profile_id = 1
              AND offers.course_id IN (#{courses_ids.join(',')})
              LIMIT 1;
          SQL
          raise 'not uab student' if allocations.empty?
        end

        verify_permission(:index, user.allocations.where(profile_id: 1, status: 1).map(&:allocation_tag).map(&:related).flatten.uniq)
        {
          country: user.country, state: user.state, city: user.city, zipcode: user.zipcode, address: user.address, address_number: user.address_number, address_complement: user.address_complement, address_neighborhood: user.address_neighborhood, zipcode: user.zipcode, special_needs: user.special_needs
        }

      end

    end # namespace
  end
end
