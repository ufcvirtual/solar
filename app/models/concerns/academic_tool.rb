require 'active_support/concern'

module AcademicTool
  extend ActiveSupport::Concern

  included do
    has_many :academic_allocations, as: :academic_tool, dependent: :destroy
    has_many :allocation_tags, through: :academic_allocations
    has_many :groups, through: :allocation_tags

    after_create :define_academic_associations

    attr_accessor :allocation_tag_ids_associations
  end

  private

    def define_academic_associations
      academic_allocations.create allocation_tag_ids_associations.map {|at| {allocation_tag_id: at}}
    end

end
