require 'active_support/concern'

module AcademicTool
  extend ActiveSupport::Concern

  included do
    has_many :academic_allocations, as: :academic_tool, dependent: :destroy
    has_many :allocation_tags, through: :academic_allocations
    has_many :groups, through: :allocation_tags
    has_many :offers, through: :allocation_tags

    after_create :define_academic_associations, unless: 'allocation_tag_ids_associations.nil?'

    before_validation :set_schedule, if: 'respond_to?(:schedule)'

    attr_accessor :allocation_tag_ids_associations
  end

  private

    def define_academic_associations
      unless allocation_tag_ids_associations.blank?
        academic_allocations.create allocation_tag_ids_associations.map {|at| { allocation_tag_id: at }}
      else
        academic_allocations.create
      end
    end

    def set_schedule
      self.schedule.check_end_date = true # mandatory final date
      self.schedule.verify_offer_ats = allocation_tag_ids_associations
    end

end

