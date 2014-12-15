module V1
  class SupportMaterialFiles < Base

    guard_all!

    namespace :groups do

      ## api/v1/groups/1/lessons
      desc "Lista de material de apoio da turma"
      params { requires :id, type: Integer, desc: "ID da turma" }
      get ":id/support_material_files" do
      # get ":id/support_material_files", rabl: "support_material_files/list" do
        @ats = RelatedTaggable.related(group_id: params[:id])
        @material_files = SupportMaterialFile.list(@ats)

        @material_files.map do |folder, files|
          {
            folder_name: folder,
            files: files.map do |file|
              {
                id: file.id,
                type: file.type_info,
                name: file.name,
                url: file.url || "/api/v1/support_material_files/#{file.id}/download"
              }
            end
          }
        end
      end

    end # namespace

    namespace :support_material_files do
      desc "Download material de apoio"
      params { requires :id, type: Integer, desc: "ID do material de apoio" }
      get ":id/download" do
        file = SupportMaterialFile.find(params[:id])
        begin
          raise if file.is_link?

          filename = Digest::MD5.hexdigest(file.attachment_file_name)

          content_type MIME::Types.type_for(file.attachment_file_name)[0].to_s
          env['api.format'] = :binary
          header "Content-Disposition", "attachment; filename*=UTF-8''#{URI.escape(filename)}"

          File.open(file.attachment.path).read
        rescue
          raise ActiveRecord::RecordNotFound
        end
      end
    end # namespace

  end
end
