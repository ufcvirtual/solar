class SupportMaterialFile < ActiveRecord::Base

  belongs_to :allocation_tag

  validates :attachment_file_name, :presence => true

  has_attached_file :attachment,
    :path => ":rails_root/media/support_material_file/:id_:basename.:extension",
    :url => "/media/support_material_file/:id_:basename.:extension"

  validates_attachment_size :attachment, :less_than => 5.megabyte, :message => " "
  validates_attachment_content_type_in_black_list :attachment

  ##
  # Recupera arquivos
  ##
  def self.find_files(allocation_tag_ids, folder_name = nil)
    in_folder = " AND sm.folder = '#{folder_name}' " unless folder_name.nil?

    query = <<SQL
    SELECT *
      FROM support_material_files sm
     WHERE allocation_tag_id in (#{allocation_tag_ids.join(",")}) #{in_folder}
     ORDER BY sm.folder, sm.attachment_content_type, sm.attachment_file_name
SQL

    SupportMaterialFile.find_by_sql(query);
  end

  ##
  # DEPRECATED - Utilizar find_files
  #
  # Recupera arquivos por allocation
  ##
  def self.search_files(allocation_tag_id, folder_name = nil)
    related_allocation_tag_ids = AllocationTag.find_related_ids(allocation_tag_id)
    in_folder = " AND sm.folder = '#{folder_name}' " unless folder_name.nil?

    query = <<SQL
    SELECT *
      FROM support_material_files sm
     WHERE allocation_tag_id in (#{related_allocation_tag_ids.join(",")})
           #{in_folder}
     ORDER BY sm.folder, sm.attachment_content_type, sm.attachment_file_name
SQL

    SupportMaterialFile.find_by_sql(query);
  end

  ##
  # Editor
  ##
  def self.upload_link(allocation_tag_id,url)
    ActiveRecord::Base.connection.select_all <<SQL
    INSERT INTO support_material_files (allocation_tag_id, attachment_content_type,attachment_updated_at, folder, url)
    VALUES (#{allocation_tag_id}, 'link' ,CURRENT_TIMESTAMP ,'LINKS' , '#{url}')
SQL
  end

end
