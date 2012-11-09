class SupportMaterialFile < ActiveRecord::Base

  belongs_to :allocation_tag

  validates :attachment_file_name, :presence => true

  has_attached_file :attachment,
    :path => ":rails_root/media/support_material_files/:id_:basename.:extension",
    :url => "/media/support_material_files/:id_:basename.:extension"

  validates_attachment_size :attachment, :less_than => 5.megabyte, :message => " "
  validates_attachment_content_type_in_black_list :attachment

  ##
  # Recupera arquivos
  ##
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

  ##
  # Editor
  ##
  def self.upload_link(allocation_tag_id,url)
    ActiveRecord::Base.connection.select_all <<SQL
    INSERT INTO support_material_files (allocation_tag_id, attachment_content_type,attachment_updated_at, folder, url)
    VALUES (#{allocation_tag_id}, 'link' ,CURRENT_TIMESTAMP ,'LINKS' , '#{url}')
SQL
  end

  ############### editor ########################

  def self.list_folders(current_user) # lista para combobox das pastas
    query = <<SQL
   SELECT DISTINCT t1.folder, t1.allocation_tag_id
      FROM support_material_files AS t1
        JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
        JOIN allocations AS t3 ON t2.id = t3.allocation_tag_id
      WHERE t3.user_id IN (#{current_user});
SQL

    ActiveRecord::Base.connection.select_all query
  end

  def self.select_every_curriculum(current_user)
    query = <<SQL
    SELECT DISTINCT t2.id allocation_tag_id, t2.group_id, t2.offer_id, t2.curriculum_unit_id, t2.course_id
      FROM allocations AS t1
        JOIN allocation_tags AS t2 ON t1.allocation_tag_id = t2.id
      WHERE t1.user_id IN (#{current_user}) AND
       t1.profile_id = 5;
SQL

    ActiveRecord::Base.connection.select_all query
  end

  def self.select_unit_editor(validy_id_allocation_tag)
    allocationTag = AllocationTag.find_all_by_id(validy_id_allocation_tag)[0]

    # O valor não nulo, além da id, na tupla da 'allocation_tag' é selecionada
    id_not_null = allocationTag.group_id if !allocationTag.group_id.nil?
    id_not_null = allocationTag.offer_id if !allocationTag.offer_id.nil?
    id_not_null = allocationTag.curriculum_unit_id if !allocationTag.curriculum_unit_id.nil?
    id_not_null = allocationTag.course_id if !allocationTag.course_id.nil?

    
    if !allocationTag.group_id.nil?
      query = <<SQL
      SELECT DISTINCT t1.id group_id, t1.code, t1.offer_id, t2.semester,  t2.curriculum_unit_id, t3.name curriculum_unit, t2.course_id, t4.name course
        FROM groups AS t1
          JOIN offers AS t2 ON t1.offer_id = t2.id
          JOIN curriculum_units AS t3 ON t2.curriculum_unit_id = t3.id
          JOIN courses AS t4 ON t4.id = t2.course_id
            WHERE t1.id IN (#{id_not_null});
SQL
    end
    
    if !allocationTag.offer_id.nil?
      query = <<SQL
      SELECT DISTINCT t1.id group_id, t1.code, t1.offer_id, t2.semester,  t2.curriculum_unit_id, t3.name curriculum_unit, t2.course_id, t4.name course
        FROM groups AS t1
          JOIN offers AS t2 ON t1.offer_id = t2.id
          JOIN curriculum_units AS t3 ON t2.curriculum_unit_id = t3.id
          JOIN courses AS t4 ON t4.id = t2.course_id
          WHERE t2.id IN (#{id_not_null});
SQL
    end

    if !allocationTag.curriculum_unit_id.nil?
       query = <<SQL
      SELECT DISTINCT t1.id group_id, t1.code, t1.offer_id, t2.semester,  t2.curriculum_unit_id, t3.name curriculum_unit, t2.course_id, t4.name course
        FROM groups AS t1
            JOIN offers AS t2 ON t1.offer_id = t2.id
            JOIN curriculum_units AS t3 ON t2.curriculum_unit_id = t3.id
            JOIN courses AS t4 ON t4.id = t2.course_id
          WHERE t3.id IN (#{id_not_null});
SQL
    end

    if !allocationTag.course_id.nil?
       query = <<SQL
      SELECT DISTINCT t1.id group_id, t1.code, t1.offer_id, t2.semester,  t2.curriculum_unit_id, t3.name curriculum_unit, t2.course_id, t4.name course
        FROM groups AS t1
          JOIN offers AS t2 ON t1.offer_id = t2.id
          JOIN curriculum_units AS t3 ON t2.curriculum_unit_id = t3.id
          JOIN courses AS t4 ON t4.id = t2.course_id
            WHERE t4.id IN (#{id_not_null});
SQL
    end

      ActiveRecord::Base.connection.select_all query
    end


#################### editor #########################


end