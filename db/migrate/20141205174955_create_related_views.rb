class CreateRelatedViews < ActiveRecord::Migration
  def up
    # create_view :related_curriculum_units, File.read(Rails.root.join("db/views/at_related_curriculum_units.sql"))
    # create_view :related_offers, File.read(Rails.root.join("db/views/at_related_offers.sql"))
    # create_view :related_groups, File.read(Rails.root.join("db/views/at_related_groups.sql"))

    execute File.read(Rails.root.join("db/views/at_related_curriculum_units.sql"))
    execute File.read(Rails.root.join("db/views/at_related_offers.sql"))
    execute File.read(Rails.root.join("db/views/at_related_groups.sql"))

  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS vw_at_related_curriculum_units;
      DROP VIEW IF EXISTS vw_at_related_offers;
      DROP VIEW IF EXISTS vw_at_related_groups;
    SQL

    # drop_view :related_curriculum_units, if_exists: true
    # drop_view :related_offers, if_exists: true
    # drop_view :related_groups, if_exists: true
  end
end
