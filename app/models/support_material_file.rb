class SupportMaterialFile < ActiveRecord::Base
  has_one :allocation_tag

  validates :allocation_tag_id, presence: true
  validates :attachment, presence: true, unless: :is_link?
  before_save :set_and_validate_url, if: :is_link?

  has_attached_file :attachment,
    :path => ":rails_root/media/support_material_files/:id_:basename.:extension",
    :url => "/media/support_material_files/:id_:basename.:extension"

  validates_attachment_size :attachment, :less_than => 5.megabyte, :message => ""
  validates_attachment_content_type_in_black_list :attachment

  def set_and_validate_url
    is_valid = URI.parse(url).kind_of?(URI::HTTP) rescue false # valida http e https
    self.url = "http://#{url}" unless is_valid
  end

  def name
    return "" if url.nil? and attachment_file_name.nil?
    return url unless url.nil?
    return attachment_file_name
  end

  def is_link?
    (material_type == Material_Type_Link)
  end

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