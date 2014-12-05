CREATE OR REPLACE VIEW vw_at_related_groups AS

    SELECT g.id       AS group_id,
           g_at.id    AS group_at_id,

           g.status   AS group_status,

           o.id       AS offer_id,
           o_at.id    AS offer_at_id,

           s.id       AS semester_id,

           uc.id      AS curriculum_unit_id,
           uc_at.id   AS curriculum_unit_at_id,

           c.id       AS course_id,
           c_at.id    AS course_at_id,

           uct.id     AS curriculum_unit_type_id,
           uct_at.id  AS curriculum_unit_type_at_id,

           COALESCE(o.offer_schedule_id, s.offer_schedule_id) AS offer_schedule_id

      FROM groups                 AS g
      JOIN allocation_tags        AS g_at   ON g_at.group_id = g.id
      JOIN offers                 AS o      ON o.id = g.offer_id
      JOIN semesters              AS s      ON s.id = o.semester_id
      JOIN allocation_tags        AS o_at   ON o_at.offer_id = o.id
 LEFT JOIN curriculum_units       AS uc     ON uc.id = o.curriculum_unit_id
 LEFT JOIN allocation_tags        AS uc_at  ON uc_at.curriculum_unit_id = uc.id
 LEFT JOIN curriculum_unit_types  AS uct    ON uct.id = uc.curriculum_unit_type_id
 LEFT JOIN allocation_tags        AS uct_at ON uct_at.curriculum_unit_type_id = uct.id
 LEFT JOIN courses                AS c      ON c.id = o.course_id
 LEFT JOIN allocation_tags        AS c_at   ON c_at.course_id = c.id
     ORDER BY g.id;
