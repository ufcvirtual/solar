module V1
  class Loads < Base
    namespace :load

    before do
      verify_ip_access!
    end

    helpers do
      def verify_or_create_curriculum_unit(code, name, working_hours, credits, type = 2)
        uc = CurriculumUnit.where(code: code.slice(0..9)).first_or_initialize

        uc.attributes = {name: name.slice(0..119), working_hours: working_hours, credits: credits, curriculum_unit_type: (CurriculumUnitType.find(type) || CurriculumUnitType.find(2))}
        uc.attributes = {resume: name, objectives: name, syllabus: name} if uc.new_record?

        uc.save!

        uc
      end

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

    end

    namespace :groups do
      # POST load/groups
      post "/" do
        load_group    = params[:turmas]
        cpfs          = load_group[:professores]
        semester_name = load_group[:periodo].blank? ? load_group[:ano] : "#{load_group[:ano]}.#{load_group[:periodo]}"
        offer_period  = { start_date: load_group[:dtInicio].to_date, end_date: load_group[:dtFim].to_date }
        group_code    = load_group[:codigo]
        course        = Course.find_by_code! load_group[:codGraduacao]
        uc            = CurriculumUnit.find_by_code! load_group[:codDisciplina]

        begin
          ActiveRecord::Base.transaction do 
            semester = verify_or_create_semester(semester_name, offer_period)
            offer    = verify_or_create_offer(semester, course, uc, offer_period)
            group    = verify_or_create_group(offer, group_code)

            allocate_professors(group, cpfs)
          end

          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end
      end

      # POST load/groups/enrollments
      post :enrollments do
        load_enrollments = params[:matriculas]
        user             = verify_or_create_user(load_enrollments[:cpf])
        groups           = JSON.parse(load_enrollments[:turmas])
        student_profile  = 1 # Aluno => 1

        begin
          ActiveRecord::Base.transaction do
            groups = groups.collect do |group_info|
              get_group(group_info["codDisciplina"], group_info["codGraduacao"], group_info["codigo"], group_info["periodo"], group_info["ano"]) unless group_info["codDisciplina"] == 78
            end # Se cód. graduação for 78, desconsidera (por hora, vem por engano).

            cancel_previous_and_create_allocations(groups.compact, user, student_profile)
          end

          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end
      end

      # GET load/groups/enrollments
      params { requires :codDisciplina, :codGraduacao, :codTurma, :periodo, :ano }
      get :enrollments, rabl: "users/enrollments" do
        group  = get_group(params[:codDisciplina], params[:codGraduacao], params[:codTurma], params[:periodo], params[:ano])
        raise ActiveRecord::RecordNotFound if group.nil?
        begin 
          @users = group.students_participants.map(&:user)
        rescue  => error
          error!({error: error}, 422)
        end
      end

      # load/groups/allocate_user
      # params { requires :cpf, :perfil, :codDisciplina, :codGraduacao, :codTurma, :periodo, :ano }
      put :allocate_user do # Receives user's cpf, group and profile to allocate
        begin
          allocation = params[:allocation]
          user       = verify_or_create_user(allocation[:cpf])
          profile_id = get_profile_id(allocation[:perfil])

          destination = get_destination(allocation[:codDisciplina], allocation[:codGraduacao], allocation[:codTurma], allocation[:periodo], allocation[:ano])
          destination.allocate_user(user.id, profile_id)

          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end
      end # allocate_profile

      # load/groups/block_profile
      put :block_profile do # Receives user's cpf, group and profile to block
        allocation = params[:allocation]
        user       = User.find_by_cpf!(allocation[:cpf].to_s.delete('.').delete('-'))
        new_status = 2 # canceled allocation
        group_info = allocation[:turma]
        profile_id = get_profile_id(allocation[:perfil])

        begin
          destination = get_destination(group_info[:codDisciplina], group_info[:codGraduacao], group_info[:codigo], group_info[:periodo], group_info[:ano])
          destination.change_allocation_status(user.id, new_status, profile_id: profile_id) if destination

          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end
      end # block_profile

    end # groups

    namespace :curriculum_units do
      # load/curriculum_units/editors
      post :editors do
        load_editors  = params[:editores]
        uc            = CurriculumUnit.find_by_code!(load_editors[:codDisciplina])
        cpf_editores  = load_editors[:editores].map {|c| c.delete('.').delete('-')}
        users         = User.where(cpf: cpf_editores)
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

      # load/curriculum_units
      params do 
        requires :codigo, :nome
        requires :cargaHoraria, type: Integer
        requires :creditos, type: Float
        optional :tipo, type: Integer
      end
      post "/" do
        begin
          ActiveRecord::Base.transaction do 
            verify_or_create_curriculum_unit(params[:codigo], params[:nome], params[:cargaHoraria], params[:creditos], (params[:tipo].nil? ? 2 : params[:tipo]))
          end
          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end
      end
    end #curriculum_units

    namespace :user do
      params { requires :cpf }
      # load/user
      post "/" do
        begin
          user = User.new cpf: params[:cpf]
          ma_response = user.connect_and_validates_user
          raise ActiveRecord::RecordNotFound if ma_response.nil? # nao existe no MA
          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end
      end
    end

  end

end
