class SupportMaterialFile < ActiveRecord::Base

  belongs_to :allocation_tag

  validates :attachment_file_name, :presence => true

  ################################
  # attachment files
  ################################

  has_attached_file :attachment,
    :path => ":rails_root/media/support_material_file/:id_:basename.:extension",
    :url => "/media/support_material_file/:id_:basename.:extension"

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
      ORDER BY sm.folder, sm.attachment_content_type, sm.name
    "
    return SupportMaterialFile.find_by_sql(sql);
  end
end
