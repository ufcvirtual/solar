module V1
  class Taggables < Base
    # methods used for any taggable

    before { verify_ip_access! }

    desc "Remove curso ou disciplina ou oferta ou turma"
    params { requires :type, type: String, values: ['curriculum_unit', 'course', 'offer', 'group'] }
    delete "/taggables/:type/:id" do
      begin
        (object = params[:type].capitalize.constantize.find(params[:id])).destroy
        raise object.errors.full_messages unless (object.nil? || object.errors.empty?)
        { ok: :ok }
      rescue
        raise object.errors.full_messages
      end
    end

  end
end