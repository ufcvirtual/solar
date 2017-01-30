module V1
  class SupportMaterialFiles < Base
    namespace :groups do
      before do
        @ats = RelatedTaggable.related(group_id: params[:id])
      end

      ## api/v1/groups/1/lessons
      desc "Lista de material de apoio da turma"
      params { requires :id, type: Integer, desc: "ID da turma" }
      get ":id/support_material_files" do
        authorize! :index, SupportMaterialFile, on: @ats, read: true
        raise 'exam' if Exam.verify_blocking_content(current_user.id) || false

        # get ":id/support_material_files", rabl: "support_material_files/list" do
        @material_files = SupportMaterialFile.list(@ats)
        @material_files.map do |folder, files|
          {
            folder_name: folder,
            files: files.map do |file|
              {
                id: file.id,
                type: file.type_info,
                content_type: file.attachment_content_type,
                name: file.name,
                url: file.url || "/api/v1/groups/#{params[:id]}/support_material_files/#{file.id}/download"
              }
            end
          }
        end
      end # get

      desc "Download material de apoio"
      params { requires :id, type: Integer, desc: "ID do material de apoio" }
      get ":id/support_material_files/:file_id/download" do
        authorize! :download, SupportMaterialFile, on: @ats, read: true
        raise 'exam' if Exam.verify_blocking_content(current_user.id) || false

        file = SupportMaterialFile.find(params[:file_id])
        send_file(file.attachment.path.to_s)
      end # get download

    end # namespace
  end
end
