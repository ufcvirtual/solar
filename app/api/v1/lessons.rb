module V1
  class Lessons < Base

    namespace :lessons do
      ## aulas publicas
      before { verify_ip_access! }

      ## api/v1/lessons
      get "/" do
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

          courses << {course: at_dtd[:course], discipline: at_dtd[:curriculum_unit], lesson: {id: lesson.id, name: lesson.name, url: lesson.address}}
        end
        courses
      end # get /
    end

    segment do
      before { guard! }

      namespace :groups do

        ## api/v1/groups/1/lessons
        desc "Lista de aulas da turma"
        params { requires :id, type: Integer }
        get ":id/lessons", rabl: "lessons/list" do
          @ats = RelatedTaggable.related(group_id: params[:id])
          @lessons_modules = LessonModule.to_select(@ats, current_user, list = true)
        end

      end # namespace

    end # segment


  end
end
