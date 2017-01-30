module V1
  class Lessons < Base
    namespace :groups do
      before do
        @ats = RelatedTaggable.related(group_id: @group_id = params[:group_id])
      end

      ## api/v1/groups/1/lessons
      desc "Lista de aulas da turma"
      params { requires :group_id, type: Integer }
      get ":group_id/lessons", rabl: "lessons/list" do
        guard!
        raise 'exam' if Exam.verify_blocking_content(current_user.id) || false
        @lessons_modules = LessonModule.to_select(@ats, current_user, list = true)
      end
    end # namespace groups


  # get '/media/lessons/:id/:file(.:extension)', to: 'access_control#lesson', index: true
  # get '/media/lessons/:id/:folder/*path',    to: 'access_control#lesson', index: false
    namespace :lessons do
      ## aulas publicas

      ## api/v1/lessons
      get "/" do
        verify_ip_access_and_guard!
        raise 'exam' if Exam.verify_blocking_content(current_user.id) || false

        if params[:disconsider].present?
          disconsider = params[:disconsider]
          query_not = 'id > ?'
        end

        lessons = Lesson.where(type_lesson: Lesson_Type_Link, status: Lesson_Approved).where("address ~ 'www.virtual.ufc.br'").where(query_not, disconsider)

        courses = []
        lessons.each do |lesson|
          academic_al = lesson.academic_allocations.first
          at = academic_al.allocation_tag
          at_dtd = at.send(at.refer_to).detailed_info

          courses << { course: at_dtd[:course], discipline: at_dtd[:curriculum_unit], lesson: { id: lesson.id, name: lesson.name, url: lesson.address } }
        end
        courses
      end # get /
    end # namespace lessons
  end
end
