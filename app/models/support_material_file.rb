class SupportMaterialFile < ActiveRecord::Base

  belongs_to :allocation_tag

  validates :attachment_file_name, :presence => true

  ################################
  # attachment files
  ################################

  has_attached_file :attachment,
    :path => ":rails_root/media/support_material_file/:id_:basename.:extension",
    :url => "/media/support_material_file/:id_:basename.:extension"

  validates_attachment_size :attachment, :less_than => 5.megabyte, :message => " "

  validates_attachment_content_type_in_black_list :attachment



  def self.search_files(allocation_tag_id)

    #Ids das allocationTags relacionadas à consulta
    relatedAllocationTagIds = AllocationTag.find_related_ids(allocation_tag_id.to_s)

    sql = "
      SELECT
        *
      FROM
        support_material_files sm
      where
        allocation_tag_id in (#{relatedAllocationTagIds.join(",")})
      ORDER BY sm.folder, sm.attachment_content_type, sm.attachment_file_name
    "
    return SupportMaterialFile.find_by_sql(sql);
  end

  ###################
  #                 #
  #     EDITOR      #
  #                 #
  ###################

  def self.upload_link(allocation_tag_id,url)
    ActiveRecord::Base.connection.select_all <<SQL

    INSERT INTO support_material_files (allocation_tag_id, attachment_content_type,attachment_updated_at, folder, url)
    VALUES (#{allocation_tag_id}, 'link' ,CURRENT_TIMESTAMP ,'LINKS' , '#{url}')

SQL
  end

end
