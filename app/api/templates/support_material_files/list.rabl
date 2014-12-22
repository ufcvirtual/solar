# @material_files.map do |folder, files|
#   {
#     folder_name: folder,
#     files: files.map do |file|
#       {
#         id: file.id,
#         type: file.type_info,
#         name: file.name,
#         url: file.url || "/api/v1/support_material_files/#{file.id}/download"
#       }
#     end
#   }
# end
