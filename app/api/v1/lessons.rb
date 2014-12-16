module V1
  class Lessons < Base

    namespace :groups do
      before { guard! }

      ## api/v1/groups/1/lessons
      desc "Lista de aulas da turma"
      params { requires :id, type: Integer }
      get ":id/lessons", rabl: "lessons/list" do
        @ats = RelatedTaggable.related(group_id: params[:id])
        @lessons_modules = LessonModule.to_select(@ats, current_user, list = true)
      end

    end # namespace groups

    namespace :lessons do
      ## aulas publicas

      ## api/v1/lessons
      get "/" do
        verify_ip_access!

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

      ## api/v1/lessons/1/aula1/index.thml
      desc "Acessa aula"
      get ":id(/:folder)/*path" do
        lesson = Lesson.find(params[:id])

        # guarda acesso apenas para o arquivo inicial
        guard! if lesson.address == (relative_path = File.join([params[:folder], params[:path]].compact))
        file_path = Lesson::FILES_PATH.join(params[:id], relative_path)

        send_file(file_path.to_s, file_path.to_s)
      end # get folder

    end # namespace lessons

  end
end
