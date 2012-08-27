class CommentFile < ActiveRecord::Base

  belongs_to :assignment_comment

  validates :attachment_file_name, :presence => true

  has_attached_file :attachment,
    :path => ":rails_root/media/portfolio/comments/:id_:basename.:extension",
    :url => "/media/portfolio/comments/:id_:basename.:extension"

  validates_attachment_size :attachment, :less_than => 5.megabyte, :message => " "

  validates_attachment_content_type_in_black_list :attachment

  ##
  # Deleta arquivo do comentário
  ##
  def delete_comment_file
    begin
      file = "#{::Rails.root.to_s}/media/portfolio/comments/#{id}_#{attachment_file_name}" #recupera arquivo
      if delete #se deletar arquivo da base de dados com sucesso
        File.delete(file) if File.exist?(file) #deleta arquivo do servidor
      else
        raise t(:error_delete_file)
      end
    rescue Exception => error
      flash[:alert] = error.message
    end
  end

end
