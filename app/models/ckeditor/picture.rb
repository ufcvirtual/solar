class Ckeditor::Picture < Ckeditor::Asset
  has_attached_file :data,
                    url: '/media/ckeditor/pictures/:id_:style_:basename.:extension',
                    path: ':rails_root/media/ckeditor/pictures/:id_:style_:basename.:extension',
                    styles: { content: '800>', thumb: '118x100#' }

  validates_attachment_presence :data
  validates_attachment_size :data, less_than: 2.megabytes
  validates_attachment_content_type :data, content_type: /\Aimage/

  def url_content
    url(:content)
  end

  def self.inheritance_column 
    nil 
  end
end
