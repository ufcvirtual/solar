class PublicFile < ActiveRecord::Base

  belongs_to :user
  belongs_to :allocation_tag

  validates :attachment_file_name, :presence => true

  has_attached_file :attachment,
    :path => ":rails_root/media/assignment/public_area/:id_:basename.:extension",
    :url => "/media/assignment/public_area/:id_:basename.:extension"

  validates_attachment_size :attachment, :less_than => 5.megabyte, :message => " "

  validates_attachment_content_type_in_black_list :attachment

  default_scope :order => 'attachment_updated_at DESC'

  ##
  # Deleta arquivo publico
  ##
  def delete_public_file
    begin
      file = "#{::Rails.root.to_s}/media/assignment/public_area/#{id}_#{attachment_file_name}" #recupera arquivo
      if delete #se deletar arquivo da base de dados com sucesso
        File.delete(file) if File.exist?(file) #deleta arquivo do servidor
      else
        flash[:alert] = t(:error_delete, :scope => [:assignment, :files])
      end
    rescue Exception => error
      flash[:alert] = error.message
    end
  end

  ##
  # Arquivos da area publica
  ##
  def self.all_by_class_id_and_user_id(class_id, user_id)
    return(PublicFile.all(:conditions => ["users.id = #{user_id} AND allocation_tags.group_id = #{class_id}"], :include => [:allocation_tag, :user], :select => ["attachment_file_name, attachment_content_type, attachment_file_size, attachment_updated_at"]))
  end

end
