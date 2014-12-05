# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggersGroupsUpdateAndOffersUpdateAndCurriculumUnitsUpdate < ActiveRecord::Migration
  def up
    create_trigger("groups_after_update_of_offer_id_status_row_tr", :generated => true, :compatibility => 1).
        on("groups").
        after(:update).
        of(:offer_id, :status) do
      <<-SQL
      UPDATE related_taggables
         SET group_status = NEW.status,
             offer_id = NEW.offer_id,
             offer_at_id = (SELECT id FROM allocation_tags WHERE offer_id = NEW.offer_id)
       WHERE group_id = OLD.id;
      SQL
    end

    create_trigger("offers_after_update_of_curriculum_unit_id_course_id_offer_sc_tr", :generated => true, :compatibility => 1).
        on("offers").
        after(:update).
        of(:curriculum_unit_id, :course_id, :offer_schedule_id) do
      <<-SQL

      -- curriculum unit id
      IF NEW.curriculum_unit_id <> OLD.curriculum_unit_id THEN
        UPDATE related_taggables
           SET curriculum_unit_id = NEW.curriculum_unit_id,
               curriculum_unit_at_id = (SELECT id FROM allocation_tags WHERE curriculum_unit_id = NEW.curriculum_unit_id)
         WHERE offer_id = OLD.id;
      END IF;

      -- course
      IF NEW.course_id <> OLD.course_id THEN
        UPDATE related_taggables
           SET course_id = NEW.course_id,
               course_at_id = (SELECT id FROM allocation_tags WHERE course_id = NEW.course_id)
         WHERE offer_id = OLD.id;
      END IF;

      -- offer shedule
      IF NEW.offer_schedule_id <> OLD.offer_schedule_id OR (NEW.offer_schedule_id IS NULL) <> (OLD.offer_schedule_id IS NULL) THEN
        IF NEW.offer_schedule_id IS NULL THEN
          -- se setar null tem q mudar para o schedule para o do semestre
          UPDATE related_taggables
             SET offer_schedule_id = (SELECT offer_schedule_id FROM semesters WHERE id = NEW.semester_id)
           WHERE offer_id = OLD.id;
        ELSE
          UPDATE related_taggables
             SET offer_schedule_id = NEW.offer_schedule_id
           WHERE offer_id = OLD.id;
        END IF;

      END IF;
      SQL
    end

    create_trigger("curriculum_units_after_update_of_curriculum_unit_type_id_row_tr", :generated => true, :compatibility => 1).
        on("curriculum_units").
        after(:update).
        of(:curriculum_unit_type_id) do
      <<-SQL
      -- update as linhas onde o curriculum unit esta para mudar o tipo
      UPDATE related_taggables
         SET curriculum_unit_type_id = NEW.curriculum_unit_type_id,
             curriculum_unit_type_at_id = (SELECT id FROM allocation_tags WHERE curriculum_unit_type_id = NEW.curriculum_unit_type_id)
       WHERE curriculum_unit_id = OLD.id;
      SQL
    end
  end

  def down
    drop_trigger("groups_after_update_of_offer_id_status_row_tr", "groups", :generated => true)

    drop_trigger("offers_after_update_of_curriculum_unit_id_course_id_offer_sc_tr", "offers", :generated => true)

    drop_trigger("curriculum_units_after_update_of_curriculum_unit_type_id_row_tr", "curriculum_units", :generated => true)
  end
end
