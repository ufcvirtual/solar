#require "migration_helper"
class GenerateFk < ActiveRecord::Migration
  extend MigrationHelper
  
  def self.up
    #add foreign key - offers
    add_foreign_key(:offers, :curriculum_unit_id, :curriculum_unities)
    add_foreign_key(:offers, :course_id, :courses)

    #add foreign key - classes
    add_foreign_key(:classes, :offer_id, :offers)
    
    #add foreign key - allocations
    add_foreign_key(:allocations, :user_id, :users)
    add_foreign_key(:allocations, :class_id, :classes)
    add_foreign_key(:allocations, :profile_id, :profiles)

    #add foreign key - enrollments
    add_foreign_key(:enrollments, :offer_id, :offers)
  end

  def self.down
    #remove foreign key - offers
    remove_foreign_key(:offers, :curriculum_unit_id)
    remove_foreign_key(:offers, :course_id)

    #remove foreign key - classes
    remove_foreign_key(:classes, :offer_id)

    #remove foreign key - allocations
    remove_foreign_key(:allocations, :user_id)
    remove_foreign_key(:allocations, :class_id)
    remove_foreign_key(:allocations, :profile_id)

    #remove foreign key - enrollments
    remove_foreign_key(:enrollments, :offer_id)
  end
  
end
