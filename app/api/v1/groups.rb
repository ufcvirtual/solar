module V1
  class Groups < Base
    namespace :curriculum_units do
      desc "Turmas da UC"
      params do
        requires :id, type: Integer
      end
      get ":id/groups", rabl: "groups/list" do
        guard!
        @groups = CurriculumUnit.where(id: params[:id]).first.try(:groups) || []
      end
    end

    ## webserver

    helpers do
      def verify_or_create_semester(name, offer_period)
        semester = Semester.where(name: name).first_or_initialize

        if semester.new_record?
          semester.build_offer_schedule offer_period
          semester.build_enrollment_schedule start_date: offer_period[:start_date], end_date: offer_period[:start_date] # one day for enrollment
          semester.verify_current_date = false # don't validates initial date
          semester.save!
        end

        semester
      end

      def verify_or_create_offer(semester, course, uc, offer_period)
        offer = Offer.where(semester_id: semester, course_id: course, curriculum_unit_id: uc).first_or_initialize

        if offer.new_record?
          ss = semester.offer_schedule
          offer.build_period_schedule(offer_period) if ss.start_date.to_date != offer_period[:start_date].to_date or ss.end_date.to_date != offer_period[:end_date].to_date # semester offer period != offer period
          offer.verify_current_date = false # don't validates initial date
          offer.save!
        end

        offer
      end

      def verify_or_create_group(offer, code)
        group = Group.where(code: code, offer_id: offer).first_or_initialize
        group.status = true
        group.save!
        group
      end

      def allocate_professors(group, cpfs)
        ## como vai ficar? como saber quem eh professor?
        ## Prof. Titular => 2
        professors = User.where(cpf: cpfs)
        professors.each do |prof|
          group.allocate_user(prof.id, 2)
        end
      end

    end

    ## modulo academico :: carga de turmas
    ## considerando que é passado uma turma por vez
    namespace :load do
      format :xml
      post :groups do
        # valid IPs
        raise ActiveRecord::RecordNotFound unless YAML::load(File.open('config/webserver.yml'))[Rails.env.to_s]['address'].include?(request.env['REMOTE_ADDR'])

        load_group    = params[:turmas]
        cpfs          = load_group[:professores]
        semester_name = "#{load_group[:ano]}.#{load_group[:periodo]}"
        offer_period  = { start_date: load_group[:dtInicio].to_date, end_date: load_group[:dtFim].to_date }
        group_code    = load_group[:codigo]
        course        = Course.find_by_code load_group[:codGraduacao]
        uc            = CurriculumUnit.find_by_code load_group[:codDisciplina]

        begin
          raise ActiveRecord::RecordNotFound if course.nil? or uc.nil?

          semester = verify_or_create_semester(semester_name, offer_period)
          offer    = verify_or_create_offer(semester, course, uc, offer_period)
          group    = verify_or_create_group(offer, group_code)

          allocate_professors(group, cpfs)

          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end
      end
    end

  end
end
