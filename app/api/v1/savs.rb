module V1
  class Savs < Base

    before { verify_ip_access! }

    namespace :sav do
      
      desc "Cadastro de questionário"
      params do
        requires :sav_id, type: Integer
        optional :group_id, type: Integer#, values: -> Group.all.map(&:id) # futuramente podemos mudar para "optinals"
        optional :groups_ids, type: Array
        requires :start_date, :end_date, type: Date
        mutually_exclusive :group_id, :groups_ids
      end
      post "/:sav_id" do
        begin
          groups = [params[:group_id] || params[:groups_ids]].flatten
          Sav.transaction do
            groups.each do |group_id|
              Sav.create! ActionController::Parameters.new(params).except("route_info").permit("sav_id", "group_id", "start_date", "end_date", "created_at").merge!({group_id: (group_id.nil? ? group_id : group_id.to_i)})
            end
          end
          {ok: :ok}
        rescue => error
          ApplicationAPI.logger puts "API error: #{error}"
          error!(error, 422)
        end
      end

      desc "Remoção de questionário"
      params do
        requires :sav_id, type: Integer
        optional :group_id, type: Integer#, values: -> Group.all.map(&:id) # futuramente podemos mudar para "optinals"
        optional :groups_ids, type: Array
        mutually_exclusive :group_id, :groups_ids
      end
      delete "/:sav_id" do
        begin
          query = ((params[:group_id].present? or params[:groups_ids].present?) ? {group_id: [params[:group_id] || params[:groups_ids]].flatten} : {})
          Sav.where({sav_id: params[:sav_id]}.merge!(query)).delete_all
          {ok: :ok}
        rescue => error
          ApplicationAPI.logger puts "API error: #{error}"
          error!(error, 422)
        end
      end

    end # sav

  end
end
