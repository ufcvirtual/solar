class Bibliography < ActiveRecord::Base

  include RelatedToGroup
  include RelatedToOffer

  def self.bibliography_filter(allocation_tags_ids)
    ActiveRecord::Base.connection.select_all  <<SQL
     SELECT DISTINCT t1.*
         FROM bibliographies as t1
        INNER JOIN allocation_tags as t2 ON (t1.allocation_tag_id = t2.id)
         LEFT JOIN offers as t4 ON (t2.offer_id = t4.id)
         LEFT JOIN groups as t5 ON (t2.offer_id = t4.id)
         LEFT JOIN courses as t6 ON (t2.course_id = t6.id)
        WHERE t2.course_id is null
          AND t2.curriculum_unit_id is null
          AND t2.id IN (#{allocation_tags_ids.join(',')})
SQL
  end

end
