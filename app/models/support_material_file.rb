class SupportMaterialFile < ActiveRecord::Base

  has_one :allocation_tag

  # validates :attachment_file_name, :presence => true
  validates :allocation_tag_id, presence: true
  validates_attachment_size :attachment, :less_than => 5.megabyte, :message => " "
  validates_attachment_content_type_in_black_list :attachment

  has_attached_file :attachment,
    :path => ":rails_root/media/support_material_files/:id_:basename.:extension",
    :url => "/media/support_material_files/:id_:basename.:extension"

  def name
    return "" if url.nil? and attachment_file_name.nil?
    return url unless url.nil?
    return attachment_file_name
  end

  def type
    return "" if url.nil? and attachment_file_name.nil?
    return "link" unless url.nil?
    return "file"
  end

  def is_link?
    return not(url.nil?)
  end

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
end