# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggerOffersUpdate < ActiveRecord::Migration
  def up
    drop_trigger("offers_after_update_of_curriculum_unit_id_course_id_semester_tr", "offers", :generated => true)

    create_trigger("offers_after_update_of_curriculum_unit_id_course_id_semester_tr", :generated => true, :compatibility => 1).
        on("offers").
        after(:update).
        of(:curriculum_unit_id, :course_id, :semester_id, :offer_schedule_id) do
      <<-SQL_ACTIONS

      -- curriculum unit id
      IF ((NEW.curriculum_unit_id <> OLD.curriculum_unit_id) OR ((NEW.curriculum_unit_id IS NULL) <> (OLD.curriculum_unit_id IS NULL))) THEN
        UPDATE related_taggables
           SET curriculum_unit_id = NEW.curriculum_unit_id,
               curriculum_unit_at_id = (SELECT id FROM allocation_tags WHERE curriculum_unit_id = NEW.curriculum_unit_id),
               curriculum_unit_type_id = (SELECT curriculum_unit_type_id FROM curriculum_units WHERE curriculum_units.id = NEW.curriculum_unit_id),
               curriculum_unit_type_at_id = (SELECT allocation_tags.id FROM allocation_tags JOIN curriculum_units ON allocation_tags.curriculum_unit_type_id = curriculum_units.curriculum_unit_type_id WHERE curriculum_units.id = NEW.curriculum_unit_id)
         WHERE offer_id = OLD.id;
      END IF;

      -- course
      IF ((NEW.course_id <> OLD.course_id) OR ((NEW.course_id IS NULL) <> (OLD.course_id IS NULL))) THEN
        UPDATE related_taggables
           SET course_id = NEW.course_id,
               course_at_id = (SELECT id FROM allocation_tags WHERE course_id = NEW.course_id)
         WHERE offer_id = OLD.id;
      END IF;

      IF NEW.semester_id <> OLD.semester_id THEN
        UPDATE related_taggables
           SET semester_id = NEW.semester_id
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
      SQL_ACTIONS
    end
  end

  def down
    drop_trigger("offers_after_update_of_curriculum_unit_id_course_id_semester_tr", "offers", :generated => true)

    create_trigger("offers_after_update_of_curriculum_unit_id_course_id_semester_tr", :generated => true, :compatibility => 1).
        on("offers").
        after(:update).
        of(:curriculum_unit_id, :course_id, :semester_id, :offer_schedule_id) do
      <<-SQL_ACTIONS

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

      IF NEW.semester_id <> OLD.semester_id THEN
        UPDATE related_taggables
           SET semester_id = NEW.semester_id
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
      SQL_ACTIONS
    end
  end
end
