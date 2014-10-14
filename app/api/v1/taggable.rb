module V1
  class Taggable < Base
    # methods used for any taggable

    segment do

      before { verify_ip_access! }

      namespace :integration do
        desc "Remove curso ou disciplina ou oferta ou turma"
        params { requires :type, type: String, values: ["curriculum_unit", "course", "offer", "group"] }
        delete ":type/:id" do
          begin
            (object = params[:type].capitalize.constantize.find(params[:id])).destroy
            raise object.errors.full_messages unless (object.nil? or object.errors.empty?)
            {ok: :ok}
          rescue
            error!(object.errors.full_messages, 422)
          end
        end
      end # integration

    end # segment

  end
end