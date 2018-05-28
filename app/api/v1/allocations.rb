module V1
  class Allocations < Base

    before { verify_ip_access_and_guard! }

    namespace :allocations do

      desc "Alocação de usuário"
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
        params do
          optional :curriculum_unit_code, :course_code, :semester, :group_name, :group_code
          at_least_one_of :curriculum_unit_code, :course_code, :semester, :group_name, :group_code
        end
        post ":type" do
          begin
            allocate(params)
            { ok: :ok }
          end
        end

      end # segment

      desc "Desativação de alocação de usuário"
      params do
        requires :type, type: String, values: ["curriculum_unit_type", "curriculum_unit", "course", "offer", "group"]
        optional :profile_id, type: Integer
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

        params do
          optional :curriculum_unit_code, :course_code, :semester, :group_name, :group_code
          at_least_one_of :curriculum_unit_code, :course_code, :semester, :group_name, :group_code
        end
        delete ":type" do
          begin
            allocate(params, true, params[:raise_error])
            { ok: :ok }
          end
        end

      end # segment

    end # allocations

    namespace :group do

      desc "Recupera usuários alocados em uma turma"
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