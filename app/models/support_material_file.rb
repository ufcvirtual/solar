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


  def self .search_files(user_id,offer_id, group_id)

    list_all = " WHERE (t2.group_id = #{group_id} OR t2.offer_id = #{offer_id})" unless group_id.nil? && offer_id.nil?

    ActiveRecord::Base.connection.select_all <<SQL
           WITH cte_allocations AS (
       SELECT t1.id           AS allocation_tag_id,
              t1.curriculum_unit_id,
              t1.offer_id,
              t1.group_id
         FROM allocation_tags AS t1
         JOIN allocations     AS t2 ON t2.allocation_tag_id = t1.id
        WHERE t2.user_id = #{user_id}
        AND t2.status = 1
    ),
    -- todas as ofertas a partir dos grupos
    cte_offers_from_groups AS (
       SELECT t2.offer_id
         FROM cte_allocations   AS t1
         JOIN groups            AS t2 ON t2.id = t1.group_id
    ),
    -- todos os grupos a partir da oferta
    cte_groups_from_offers AS (
        SELECT t3.id AS group_id
          FROM cte_allocations  AS t1
          JOIN offers           AS t2 ON t2.id = t1.offer_id
          JOIN groups           AS t3 ON t3.offer_id = t2.id
    ),
    -- juncao das allocation_tags de groups e offers
    cte_all_allocation_tags AS (
     (
        SELECT t1.id AS allocation_tag_id,
               t1.offer_id,
               t1.group_id
          FROM allocation_tags          AS t1
          JOIN cte_offers_from_groups   AS t2 ON t2.offer_id = t1.offer_id
     )
     UNION
     (
        SELECT allocation_tag_id,
               offer_id,
               group_id
          FROM cte_allocations
         WHERE group_id IS NOT NULL OR offer_id IS NOT NULL
     )
     UNION
     (
         SELECT t1.id AS allocation_tag_id,
                t1.offer_id,
                t1.group_id
           FROM allocation_tags AS t1
           JOIN cte_groups_from_offers AS t2 ON t2.group_id = t1.group_id
     )
     )

    SELECT t1.attachment_file_name , t1.attachment_file_size , t1. attachment_updated_at , t1.folder, t1.id ,t1.allocation_tag_id
        FROM support_material_files AS t1
        INNER JOIN cte_all_allocation_tags  AS t2 ON (t1.allocation_tag_id = t2.allocation_tag_id)

        #{list_all}
        ORDER BY t1.folder,t1.attachment_content_type,t1.name

        ;
SQL

  end
end
