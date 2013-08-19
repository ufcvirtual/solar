class SupportMaterialFile < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION = true, true
  include ToolsAssociation

  has_one :allocation_tag

  before_save :url_protocol, if: :is_link?

  validates :allocation_tag_id, presence: true
  validates :attachment, presence: true, unless: :is_link?

  validates :url, presence: true, if: :is_link?
  validates_format_of :url, with: /^((http|https|ftp):\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix, if: :is_link?

  has_attached_file :attachment,
    :path => ":rails_root/media/support_material_files/:id_:basename.:extension",
    :url => "/media/support_material_files/:id_:basename.:extension"

  validates_attachment_size :attachment, :less_than => 5.megabyte, :message => ""
  validates_attachment_content_type_in_black_list :attachment

  def url_protocol
    self.url = ['http://', self.url].join if (self.url =~ URI::regexp(["ftp", "http", "https"])).nil? 
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
