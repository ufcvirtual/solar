  SELECT uc.id      AS curriculum_unit_id,
         uc_at.id   AS curriculum_unit_at_id,

         uct.id     AS curriculum_unit_type_id,
         uct_at.id  AS curriculum_unit_type_at_id

    FROM curriculum_units       AS uc
    JOIN allocation_tags        AS uc_at  ON uc_at.curriculum_unit_id = uc.id
    JOIN curriculum_unit_types  AS uct    ON uct.id = uc.curriculum_unit_type_id
    JOIN allocation_tags        AS uct_at ON uct_at.curriculum_unit_type_id = uct.id
   ORDER BY uc.id;
