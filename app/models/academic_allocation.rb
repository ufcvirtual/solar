class AcademicAllocation < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :academic_tool, polymorphic: true
  belongs_to :allocation_tag

  #Relacionamentos extras#
  has_many :sent_assignments
  has_many :group_assignments

  validate :verify_assignment_offer_date_range, if: :is_assignment?

  ## Datas da atividade devem estar no intervalo de datas da oferta
  def verify_assignment_offer_date_range
    errors.add(:base, I18n.t(:final_date_smaller_than_offer, :scope => [:assignment, :notifications], :end_date_offer => allocation_tag.group.offer.end_date.to_date)) if academic_tool.schedule.end_date > allocation_tag.group.offer.end_date
  end

  def is_assignment?
  	academic_tool_type.eql? 'Assignment'
  end

end
