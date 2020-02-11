module V1
  class Allocations < Base

    namespace :allocations do

      before do
        begin
          verify_ip_access!
        rescue
          guard_client!
        end
      end

      desc "Alocação de usuário", hidden: true

      params do
        requires :profile_id, type: Integer
        requires :type, type: String, values: ["curriculum_unit_type", "curriculum_unit", "course", "offer", "group"]
        optional :user_id, type: Integer
        optional :cpf, type: String
        optional :users_ids, :cpfs, type: Array
        optional :remove_previous_allocations, type: Boolean, default: false
        optional :remove_user_previous_allocations, type: Boolean, default: false
        optional :ma, type: Boolean, default: false
        exactly_one_of :cpf, :user_id, :users_ids, :cpfs
      end
      segment do
        post ":type/:id" do
          begin
            allocate(params)
            { ok: :ok }
          end
        end
        desc "Alocação de usuário", hidden: true
        params do
          requires :profile_id, type: Integer
          requires :type, type: String, values: ["curriculum_unit_type", "curriculum_unit", "course", "offer", "group"]
          optional :user_id, type: Integer
          optional :cpf, type: String
          optional :users_ids, :cpfs, type: Array
          optional :remove_previous_allocations, type: Boolean, default: false
          optional :remove_user_previous_allocations, type: Boolean, default: false
          optional :ma, type: Boolean, default: false
          optional :curriculum_unit_code, :course_code, :semester, :group_name, :group_code, type: String
          optional :start_date, :end_date, type: Date
          optional :notify_user, type: Boolean, default: false
          optional :random_group, type: Boolean, default: false
          at_least_one_of :curriculum_unit_code, :course_code, :semester, :group_name, :group_code
          mutually_exclusive :start_date, :semester
          mutually_exclusive :end_date, :semester
          mutually_exclusive :random_group, :group_code
          exactly_one_of :cpf, :user_id, :users_ids, :cpfs
        end
        post ":type" do
          begin
            if params[:random_group]
              group_id = get_group_destination_randomly(params[:curriculum_unit_code], params[:course_code], params[:start_date], params[:end_date], params[:cpf], params[:profile_id])
              allocate({type: 'group', cpf: params[:cpf], id: group_id, profile_id: params[:profile_id]}, false, false, params[:notify_user], !@current_client.blank?)
            else
              params[:group_code] = get_group_code(params[:group_code], params[:group_name]) unless params[:group_code].blank? || params[:group_name].blank?
              allocate(params, false, false, params[:notify_user], !@current_client.blank?)
            end

            { ok: :ok }
          end
        end

      end # segment

      desc "Desativação de alocação de usuário", hidden: true
      params do
        requires :type, type: String, values: ["curriculum_unit_type", "curriculum_unit", "course", "offer", "group"]
        optional :profile_id, type: Integer, default: 1
        optional :user_id, :id, type: Integer
        optional :cpf, type: String
        optional :users_ids, :cpfs, type: Array
        optional :raise_error, type: Boolean, default: true
        exactly_one_of :cpf, :user_id, :users_ids, :cpfs
      end
      segment do

        delete ":type/:id" do
          begin
            allocate(params, true, params[:raise_error])
            { ok: :ok }
          end
        end
        desc "Desativação de alocação de usuário", hidden: true
        params do
          requires :cpf, type: String
          optional :curriculum_unit_code, :course_code, :semester, :group_name, :group_code
          optional :start_date, :end_date, type: Date
          optional :notify_user, type: Boolean, default: false
          optional :random_group, type: Boolean, default: false
          at_least_one_of :curriculum_unit_code, :course_code, :semester, :group_name, :group_code
          mutually_exclusive :start_date, :semester
          mutually_exclusive :end_date, :semester
          mutually_exclusive :random_group, :group_code
          exactly_one_of :cpf

        end
        delete ":type" do
          begin
            # parametro raise_error retorna ok se mandar remover alocação que ja nao existia
            if params[:random_group]
              groups_ids = get_group_destination_randomly(params[:curriculum_unit_code], params[:course_code], params[:start_date], params[:end_date], params[:cpf], params[:profile_id], true)
              allocate({type: 'group', cpf: params[:cpf], id: groups_ids, profile_id: params[:profile_id]}, true, false, params[:notify_user], !@current_client.blank?)
            else
              params[:group_code] = get_group_code(params[:group_code], params[:group_name]) unless params[:group_code].blank? || params[:group_name].blank?
              allocate(params, true, params[:raise_error], params[:notify_user], !@current_client.blank?)
            end

            { ok: :ok }
          end
        end

      end # segment

    end # allocations

    namespace :group do

      before { verify_ip_access_and_guard! }

      desc "Recupera usuários alocados em uma turma", hidden: true
      params do
        optional :profile_id, :group_id, type: Integer
        optional :curriculum_unit_code, :course_code, :semester, :group_code, :group_name
        at_least_one_of :group_id, :group_code, :group_name
      end
      get :allocations, rabl: "users/list" do
        begin
          groups = (params[:group_id].blank? ? get_destination(params[:curriculum_unit_code], params[:course_code],params[:group_name], params[:semester], params[:group_code]) : Group.find(params[:group_id]))

          raise ActiveRecord::RecordNotFound if groups.blank?

          @users = [groups].flatten.map{|group| group.users_with_profile(params[:profile_id])}.flatten.uniq
        end
      end

    end # group

  end
end