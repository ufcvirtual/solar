module V1
  class Savs < Base

    before { verify_ip_access! }

    namespace :sav do
      
      desc "Cadastro de questionário"
      params do
        requires :questionnaire_id, type: Integer
        optional :groups_id, :profiles_ids, type: Array
        optional :course_id, :curriculum_unit_id, :curriculum_unit_type_id, :offer_id, type: Integer
        requires :start_date, :end_date, type: Date
        mutually_exclusive :groups_id, :course_id, :curriculum_unit_id, :curriculum_unit_type_id, :offer_id
      end
      post "/:questionnaire_id" do
        begin
          allocation_tags_ids = AllocationTag.get_by_params(params)[:allocation_tags]
          Sav.transaction do
            (allocation_tags_ids.blank? ? [nil] : allocation_tags_ids).each do |allocation_tag_id|
              (params[:profiles_ids].present? ? params[:profiles_ids].map(&:to_i) : [nil]).each do |profile_id|
                Sav.create! ActionController::Parameters.new(params).except("route_info").permit("questionnaire_id", "allocation_tag_id", "profile_id", "start_date", "end_date", "created_at").merge!({allocation_tag_id: allocation_tag_id, profile_id: profile_id})
              end
            end
          end
          {ok: :ok}
        rescue => error
          Rails.logger.info "[API] [ERROR] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}]: #{error}"
          error!(error, (allocation_tags_ids.nil? ? 404 : 422))
        end
      end

      desc "Edição de questionário"
      params do
        requires :questionnaire_id, type: Integer
        optional :groups_id, :profiles_ids, type: Array
        optional :course_id, :curriculum_unit_id, :curriculum_unit_type_id, :offer_id, type: Integer
        optional :start_date, :end_date, type: Date
        optional :general, type: Boolean, default: false
        mutually_exclusive :groups_id, :course_id, :curriculum_unit_id, :curriculum_unit_type_id, :offer_id
        at_least_one_of :start_date, :end_date
      end
      put "/:questionnaire_id" do
        begin
          params[:allocation_tags_ids] = AllocationTag.get_by_params(params)[:allocation_tags].compact

          query = []
          query << (params[:allocation_tags_ids].blank? ? (params[:general].present? ? "allocation_tag_id IS NULL" : nil) : "allocation_tag_id IN (:allocation_tags_ids)")
          query << (params[:profiles_ids].blank?        ? (params[:general].present? ? "profile_id IS NULL" : nil) : "profile_id IN (:profiles_ids)")

          Sav.where({questionnaire_id: params[:questionnaire_id]}).where(query.compact.join(" AND "), params).update_all({start_date: params[:start_date], end_date: params[:end_date]}.delete_if{|key,value| value.blank?})
          {ok: :ok}
        rescue => error
          Rails.logger.info "[API] [ERROR] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}]: #{error}"
          error!(error, (allocation_tags_ids.nil? ? 404 : 422))
        end
      end

      desc "Remoção de questionário"
      params do
        requires :questionnaire_id, type: Integer
        optional :groups_id, :profiles_ids, type: Array
        optional :course_id, :curriculum_unit_id, :curriculum_unit_type_id, :offer_id, type: Integer
        optional :general, type: Boolean, default: false
        mutually_exclusive :groups_id, :course_id, :curriculum_unit_id, :curriculum_unit_type_id, :offer_id
      end
      delete "/:questionnaire_id" do
        begin
          params[:allocation_tags_ids] = AllocationTag.get_by_params(params)[:allocation_tags].compact

          query = []
          query << (params[:allocation_tags_ids].blank? ? (params[:general].present? ? "allocation_tag_id IS NULL" : nil) : "allocation_tag_id IN (:allocation_tags_ids)")
          query << (params[:profiles_ids].blank?        ? (params[:general].present? ? "profile_id IS NULL" : nil) : "profile_id IN (:profiles_ids)")

          Sav.where({questionnaire_id: params[:questionnaire_id]}).where(query.compact.join(" AND "), params).delete_all
          {ok: :ok}
        rescue => error
          Rails.logger.info "[API] [ERROR] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}]: #{error}"
          error!(error, (query.nil? ? 404 : 422))
        end
      end

    end # sav

  end
end
