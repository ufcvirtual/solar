module V1
  class Allocations < Base

    segment do

      before { verify_ip_access! }

      namespace :load do

        namespace :groups do

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

      end # load

      namespace :integration do

        namespace :allocation do 
          desc "Alocação de usuário"
          params do
            requires :type, type: String, values: ["curriculum_unit_type", "curriculum_unit", "course", "offer", "group"], default: "group"
            requires :user_id, type: Integer
            requires :profile_id, type: Integer
            requires :remove_previous_allocations, type: Boolean, default: false
          end
          post ":id" do
            begin
              object = params[:type].capitalize.constantize.find(params[:id])
              object.allocate_user(params[:user_id], params[:profile_id])
              object.remove_allocations(params[:profile_id]) if params[:remove_previous_allocations]

              {ok: :ok}
            rescue => error
              error!(error, 422)
            end
          end

          desc "Desativação de alocação de usuário"
          params do
            requires :type, type: String, values: ["curriculum_unit_type", "curriculum_unit", "course", "offer", "group"], default: "group"
            requires :user_id, type: Integer
            optional :profile_id, type: Integer
          end
          delete ":id" do
            begin
              object = params[:type].capitalize.constantize.find(params[:id])
              object.unallocate_user(params[:user_id], params[:profile_id])

              {ok: :ok}
            rescue => error
              error!(error, 422)
            end
          end
        end # allocation

      end # integration

    end # segment

  end
end