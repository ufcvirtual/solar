module V1
  class Savs < Base

    before { verify_ip_access! }

    namespace :sav do
      
      desc "Cadastro de questionário"
      params do
        requires :questionnaire_id, type: Integer
        optional :groups_id, :profiles_ids, type: Array
        optional :course_id, :curriculum_unit_id, :curriculum_unit_type_id, :offer_id, :semester_id, type: Integer
        optional :start_date, :end_date, type: Date
        optional :percent, type: Integer
      end
      post "/:questionnaire_id" do
        begin
          semester_id = params.delete(:semester_id)
          allocation_tags_ids = AllocationTag.get_by_params(params)[:allocation_tags]
          Sav.transaction do
            (allocation_tags_ids.blank? ? [nil] : allocation_tags_ids).each do |allocation_tag_id|
              (params[:profiles_ids].present? ? params[:profiles_ids].map(&:to_i) : [nil]).each do |profile_id|
                Sav.create! ActionController::Parameters.new(params).except("route_info").permit("questionnaire_id", "allocation_tag_id", "profile_id", "start_date", "end_date", "created_at", "percent").merge!({allocation_tag_id: allocation_tag_id, profile_id: profile_id, semester_id: semester_id, percent: params[:percent]})
              end
            end
          end
          {ok: :ok}
        rescue => error
          log_error(error, code = (allocation_tags_ids.nil? ? 404 : 422))
          error!(error, code)
        end
      end

      desc "Edição de questionário"
      params do
        requires :questionnaire_id, type: Integer
        optional :groups_id, :profiles_ids, type: Array
        optional :course_id, :curriculum_unit_id, :curriculum_unit_type_id, :offer_id, type: Integer
        optional :start_date, :end_date, type: Date
        optional :general, type: Boolean, default: false
        optional :percent, type: Integer
        at_least_one_of :start_date, :end_date, :percent
      end
      put "/:questionnaire_id" do
        begin
          semester_id = params.delete(:semester_id)
          params[:allocation_tags_ids] = AllocationTag.get_by_params(params)[:allocation_tags].compact

          query = []
          query << (params[:allocation_tags_ids].blank? ? (params[:general].present? ? "allocation_tag_id IS NULL" : nil) : "allocation_tag_id IN (:allocation_tags_ids)")
          query << (semester_id.blank?                    ? nil : "semester_id = (:semester_id)")
          query << (params[:profiles_ids].blank?        ? (params[:general].present? ? "profile_id IS NULL" : nil) : "profile_id IN (:profiles_ids)")

          update = {start_date: params[:start_date], end_date: params[:end_date], percent: params[:percent]}.delete_if{|key,value| value.nil?}

          Sav.where({questionnaire_id: params[:questionnaire_id]}).where(query.compact.join(" AND "), params.merge!({semester_id: semester_id})).find_each{|sav| sav.update_attributes update}

          {ok: :ok}
        rescue => error
          log_error(error, code = (params[:allocation_tags_ids].nil? ? 404 : 422))
          error!(error, code)
        end
      end

      desc 'Remoção de questionário'
      params do
        requires :questionnaire_id, type: Integer
        optional :groups_id, :profiles_ids, type: Array
        optional :course_id, :curriculum_unit_id, :curriculum_unit_type_id, :offer_id, :semester_id, type: Integer
        optional :general, type: Boolean, default: false
      end
      delete "/:questionnaire_id" do
        begin
          semester_id = params.delete(:semester_id)
          params[:allocation_tags_ids] = AllocationTag.get_by_params(params)[:allocation_tags].compact

          query = []
          query << (params[:allocation_tags_ids].blank? ? (params[:general].present? ? 'allocation_tag_id IS NULL' : nil) : 'allocation_tag_id IN (:allocation_tags_ids)')
          query << (semester_id.nil?                    ? nil : 'semester_id = (:semester_id)')
          query << (params[:profiles_ids].blank?        ? (params[:general].present? ? 'profile_id IS NULL' : nil) : 'profile_id IN (:profiles_ids)')

          Sav.where({questionnaire_id: params[:questionnaire_id]}).where(query.compact.join(" AND "), params.merge!({semester_id: semester_id})).delete_all
          {ok: :ok}
        rescue => error
          log_error(error, code = (params[:allocation_tags_ids].nil? ? 404 : 422))
          error!(error, code)
        end
      end

    end # sav

  end
end
