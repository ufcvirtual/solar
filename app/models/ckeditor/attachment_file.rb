class Ckeditor::AttachmentFile < Ckeditor::Asset
  has_attached_file :data,
                    url: '/media/ckeditor/attachments/:id_:filename',
                    path: ':rails_root/media/ckeditor/attachments/:id_:filename'

  validates_attachment_presence :data
  validates_attachment_size :data, less_than: 5.megabytes

  def url_thumb
    @url_thumb ||= Ckeditor::Utils.filethumb(filename)
  end
end
