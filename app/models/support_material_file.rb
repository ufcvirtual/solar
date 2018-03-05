class SupportMaterialFile < ActiveRecord::Base
  include AcademicTool
  include FilesHelper
    
  GROUP_PERMISSION = OFFER_PERMISSION = true

  before_save :url_protocol, if: :is_link?
  before_save :define_fixed_values

  has_attached_file :attachment,
    path: ":rails_root/media/support_material_files/:id_:basename.:extension",
    url: "/media/support_material_files/:id_:basename.:extension"
  
  validates_attachment_size :attachment, less_than: 30.megabyte, message: ""
  validates_attachment_content_type_in_black_list :attachment
  do_not_validate_attachment_file_type :attachment

  validates :attachment, presence: true, unless: :is_link?
  validates :url, presence: true, if: :is_link?

  validates_format_of :url, with: /\A((http|https|ftp):\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?\z/ix, if: :is_link?



   FILES_PATH = Rails.root.join('media', 'support_material_files') # path dos arquivos de aula

  def copy_dependencies_from(material_to_copy)
    copy_file(material_to_copy, self, 'support_material_files') if material_to_copy.is_file?
  end

  def path
    return link_path if is_link?
    attachment.url
  end

  def type_info
    is_link? ? :LINK : :FILE
  end

  def url_protocol
    self.url = ['http://', self.url].join if (self.url =~ URI::regexp(['ftp', 'http', 'https'])).nil?
  end

  def name
    url || attachment_file_name || ''
  end

  def is_link?
    material_type == Material_Type_Link
  end

  def is_file?
    material_type == Material_Type_File
  end

  def link_path(api: false)
    raise 'not link' unless is_link?
    
    return 'http://www.youtube.com/embed/' + url.split('v=')[1].split('&')[0] if !api && url.include?('youtube') && !url.include?('embed') && url.include?('list')
    return 'http://www.youtube.com/embed/' + url.split('v=')[1] if !api && url.include?('youtube') && !url.include?('embed')
    url
  end

  def define_fixed_values
    self.folder = ((material_type.to_i == Material_Type_Link) ? 'LINKS' : 'GERAL')
    self.attachment_updated_at = Time.now
  end

  def self.find_files(allocation_tag_ids, folder_name = nil)
    in_folder = "folder = ?" unless folder_name.nil?

    joins(:academic_allocations).where(academic_allocations: {allocation_tag_id: allocation_tag_ids})
      .where(in_folder, folder_name).order("folder, attachment_content_type, attachment_file_name")
  end

  def self.list(at_ids)
    self.find_files(at_ids).group_by {|f| f.folder}
  end

  def self.verify_file_type(name)
    (name.last(4).eql?('.aac') || name.last(4).eql?('.m4a') || name.last(4).eql?('.mp4') || name.last(4).eql?('.m4v')) 
  end
end
