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
        send_file(file.attachment.path.to_s, file.attachment_file_name.to_s)
      end
    end # namespace

  end
end
