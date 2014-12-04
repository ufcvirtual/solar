# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggersAllocationTagsInsertAndAllocationTagsDelete < ActiveRecord::Migration
  def up
    create_trigger("allocation_tags_after_insert_row_tr", :generated => true, :compatibility => 1).
        on("allocation_tags").
        after(:insert) do
      <<-SQL_ACTIONS
      IF (NEW.group_id IS NOT NULL) THEN
        INSERT INTO related_taggables (group_id, group_at_id, group_status,
                      offer_id, offer_at_id, semester_id, curriculum_unit_id, curriculum_unit_at_id,
                      course_id, course_at_id, curriculum_unit_type_id, curriculum_unit_type_at_id, offer_schedule_id)

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
             WHERE g.id = NEW.group_id
             ORDER BY g.id;

      ELSIF (NEW.offer_id IS NOT NULL) THEN

        INSERT INTO related_taggables (offer_id, offer_at_id, semester_id,
                      curriculum_unit_id, curriculum_unit_at_id, course_id, course_at_id,
                      curriculum_unit_type_id, curriculum_unit_type_at_id, offer_schedule_id)
            SELECT o.id       AS offer_id,
                   o_at.id    AS offer_at_id,

                   s.id       AS semester_id,

                   uc.id      AS curriculum_unit_id,
                   uc_at.id   AS curriculum_unit_at_id,

                   c.id       AS course_id,
                   c_at.id    AS course_at_id,

                   uct.id     AS curriculum_unit_type_id,
                   uct_at.id  AS curriculum_unit_type_at_id,

                   COALESCE(o.offer_schedule_id, s.offer_schedule_id) AS offer_schedule_id

              FROM offers                 AS o
              JOIN semesters              AS s      ON s.id = o.semester_id
              JOIN allocation_tags        AS o_at   ON o_at.offer_id = o.id
         LEFT JOIN curriculum_units       AS uc     ON uc.id = o.curriculum_unit_id
         LEFT JOIN allocation_tags        AS uc_at  ON uc_at.curriculum_unit_id = uc.id
         LEFT JOIN curriculum_unit_types  AS uct    ON uct.id = uc.curriculum_unit_type_id
         LEFT JOIN allocation_tags        AS uct_at ON uct_at.curriculum_unit_type_id = uct.id
         LEFT JOIN courses                AS c      ON c.id = o.course_id
         LEFT JOIN allocation_tags        AS c_at   ON c_at.course_id = c.id
             WHERE o.id = NEW.offer_id
             ORDER BY o.id;

      ELSIF (NEW.curriculum_unit_id IS NOT NULL) THEN

        INSERT INTO related_taggables (curriculum_unit_id, curriculum_unit_at_id,
                      curriculum_unit_type_id, curriculum_unit_type_at_id)

            SELECT uc.id      AS curriculum_unit_id,
                   uc_at.id   AS curriculum_unit_at_id,

                   uct.id     AS curriculum_unit_type_id,
                   uct_at.id  AS curriculum_unit_type_at_id

              FROM curriculum_units       AS uc
              JOIN allocation_tags        AS uc_at  ON uc_at.curriculum_unit_id = uc.id
              JOIN curriculum_unit_types  AS uct    ON uct.id = uc.curriculum_unit_type_id
              JOIN allocation_tags        AS uct_at ON uct_at.curriculum_unit_type_id = uct.id
             WHERE uc.id = NEW.curriculum_unit_id
             ORDER BY uc.id;

      ELSIF (NEW.course_id IS NOT NULL) THEN

        INSERT INTO related_taggables (course_id, course_at_id) VALUES (NEW.course_id, NEW.id);

      ELSIF (NEW.curriculum_unit_type_id IS NOT NULL) THEN

        INSERT INTO related_taggables (curriculum_unit_type_id, curriculum_unit_type_at_id) VALUES (NEW.curriculum_unit_type_id, NEW.id);

      END IF;
      SQL_ACTIONS
    end

    create_trigger("allocation_tags_after_delete_row_tr", :generated => true, :compatibility => 1).
        on("allocation_tags").
        after(:delete) do
      <<-SQL_ACTIONS
      DELETE FROM related_taggables
            WHERE group_at_id = OLD.id
               OR offer_at_id = OLD.id
               OR course_at_id = OLD.id
               OR curriculum_unit_at_id = OLD.id
               OR curriculum_unit_type_at_id = OLD.id;
      SQL_ACTIONS
    end
  end

  def down
    drop_trigger("allocation_tags_after_insert_row_tr", "allocation_tags", :generated => true)

    drop_trigger("allocation_tags_after_delete_row_tr", "allocation_tags", :generated => true)
  end
end
