class GenerateFk < ActiveRecord::Migration
  def self.up
    #add foreign key - offers
    execute <<-SQL
      ALTER TABLE offers
        ADD CONSTRAINT fk_offers_curriculum_unit
        FOREIGN KEY (curriculum_unit_id)
        REFERENCES curriculum_unities(id)
        ON DELETE CASCADE
    SQL

    execute <<-SQL
      ALTER TABLE offers
        ADD CONSTRAINT fk_offers_course
        FOREIGN KEY (course_id)
        REFERENCES courses(id)
        ON DELETE CASCADE
    SQL

    #add foreign key - classes
    execute <<-SQL
      ALTER TABLE classes
        ADD CONSTRAINT fk_classes_offer
        FOREIGN KEY (offer_id)
        REFERENCES offers(id)
        ON DELETE CASCADE
    SQL

    #add foreign key - allocations
    execute <<-SQL
      ALTER TABLE allocations
        ADD CONSTRAINT fk_allocations_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
    SQL

    execute <<-SQL
      ALTER TABLE allocations
        ADD CONSTRAINT fk_allocations_class
        FOREIGN KEY (class_id)
        REFERENCES classes(id)
        ON DELETE CASCADE
    SQL

    execute <<-SQL
      ALTER TABLE allocations
        ADD CONSTRAINT fk_allocations_profile
        FOREIGN KEY (profile_id)
        REFERENCES profiles(id)
        ON DELETE CASCADE
    SQL

    #add foreign key - enrollment_periods
    execute <<-SQL
      ALTER TABLE enrollment_periods
        ADD CONSTRAINT fk_enrollment_periods_offer
        FOREIGN KEY (offer_id)
        REFERENCES offers(id)
        ON DELETE CASCADE
    SQL

  end

  def self.down
    #remove foreign key - offers
    execute "ALTER TABLE offers DROP CONSTRAINT fk_offers_curriculum_unit"
    execute "ALTER TABLE offers DROP CONSTRAINT fk_offers_course"

    #remove foreign key - classes
    execute "ALTER TABLE classes DROP CONSTRAINT fk_classes_offer"

    #remove foreign key - allocations
    execute "ALTER TABLE allocations DROP CONSTRAINT fk_allocations_user"
    execute "ALTER TABLE allocations DROP CONSTRAINT fk_allocations_class"
    execute "ALTER TABLE allocations DROP CONSTRAINT fk_allocations_profile"

    #remove foreign key - enrollment_periods
    execute "ALTER TABLE enrollment_periods DROP CONSTRAINT fk_enrollment_periods_offer"

  end
end
