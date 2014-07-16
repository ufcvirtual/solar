class SupportMaterialFile < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION = true, true
  
  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags

  before_save :url_protocol, if: :is_link?
  before_save :define_fixed_values

  validates :attachment, presence: true, unless: :is_link?
  validates :url, presence: true, if: :is_link?

  validates_format_of :url, with: /\A((http|https|ftp):\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?\z/ix, if: :is_link?
  validates_attachment_size :attachment, less_than: 30.megabyte, message: ""
  validates_attachment_content_type_in_black_list :attachment

  has_attached_file :attachment,
    path: ":rails_root/media/support_material_files/:id_:basename.:extension",
    url: "/media/support_material_files/:id_:basename.:extension"

  def url_protocol
    self.url = ['http://', self.url].join if (self.url =~ URI::regexp(["ftp", "http", "https"])).nil? 
  end

  def name
    url || attachment_file_name || ""
  end

  def is_link?
    (material_type == Material_Type_Link)
  end

  def self.find_files(allocation_tag_ids, folder_name = nil)
    in_folder = "folder = ?" unless folder_name.nil?

    joins(:academic_allocations).where(academic_allocations: {allocation_tag_id: allocation_tag_ids})
      .where(in_folder, folder_name).order("folder, attachment_content_type, attachment_file_name")
  end

  def define_fixed_values
    self.folder = ((material_type.to_i == Material_Type_Link) ? 'LINKS' : 'GERAL')
    self.attachment_updated_at = Time.now
  end

end
