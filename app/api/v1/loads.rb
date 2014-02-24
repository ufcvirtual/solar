module V1
  class Loads < Base
    namespace :load

    before do
      verify_ip_access!
    end

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

      def get_group(curriculum_unit_code, course_code, code, period, year)
        Group.joins(offer: :semester).where(code: code, 
          offers: {curriculum_unit_id: CurriculumUnit.where(code: curriculum_unit_code).first, 
                   course_id: Course.where(code: course_code).first},
          semesters: {name: "#{year}.#{period}"}).first
      end
    end

    namespace :groups do
      # load/groups
      post "/" do
        load_group    = params[:turmas]
        cpfs          = load_group[:professores]
        semester_name = "#{load_group[:ano]}.#{load_group[:periodo]}"
        offer_period  = { start_date: load_group[:dtInicio].to_date, end_date: load_group[:dtFim].to_date }
        group_code    = load_group[:codigo]
        course        = Course.find_by_code! load_group[:codGraduacao]
        uc            = CurriculumUnit.find_by_code! load_group[:codDisciplina]

        begin
          semester = verify_or_create_semester(semester_name, offer_period)
          offer    = verify_or_create_offer(semester, course, uc, offer_period)
          group    = verify_or_create_group(offer, group_code)

          allocate_professors(group, cpfs)

          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end
      end

      # load/groups/enrollments
      post :enrollments do
        load_enrollments = params[:matriculas]
        user             = User.find_by_cpf! load_enrollments[:cpf]
        student_profile  = 1 ## Aluno => 1
        groups           = load_enrollments[:turmas]

        begin
          groups.each do |group_info|
            group = get_group(group_info[:codDisciplina], group_info[:codGraduacao], group_info[:codigo], group_info[:periodo], group_info[:ano])
            group.allocate_user(user.id, student_profile) if group
          end

          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end
      end
    end

    namespace :curriculum_units do
      # load/curriculum_units/editors
      post :editors do
        load_editors  = params[:editores]
        uc            = CurriculumUnit.find_by_code!(load_editors[:codDisciplina])
        users         = User.where(cpf: load_editors[:editores])
        prof_editor   = 5

        begin
          users.each do |user|
            uc.allocate_user(user.id, prof_editor)
          end

          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end
      end
    end #curriculum_units

    namespace :allocations do
      # Recebe usuário, turma e perfil para bloquear.
      # load/allocations/block_profile
      post :block_profile do
        allocation   = params[:allocation]
        user         = User.find_by_cpf!(allocation[:cpf])
        new_status   = 2
        groups       = allocation[:turmas]

        begin
          groups.each do |group_info|
            group      = get_group(group_info[:codDisciplina], group_info[:codGraduacao], group_info[:codigo], group_info[:periodo], group_info[:ano])
            profile_id = group_info[:perfil]
            group.change_allocation_status(user.id, new_status, related: true, profile_id: profile_id) if group
          end

          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end

        # procura em tudo relacionado à turma
        # alocação cancelada => 2
        # recebe usuário: cpf
        # perfil: id
        # turma:
          # ano
          # periodo
          # codGraduacao
          # codDisciplina
          # codigo
        # Allocation(id: integer, user_id: integer, allocation_tag_id: integer, profile_id: integer, status: integer) 

      end #block_profile
    end #allocations

  end

end