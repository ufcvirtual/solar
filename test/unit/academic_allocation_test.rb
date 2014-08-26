require 'test_helper'

class AcademicAllocationTest < ActiveSupport::TestCase

  # fixtures :assignments, :users, :groups, :group_assignments, :schedules, :allocation_tags

  test "periodo da atividade deve fazer parte do periodo da oferta" do 

    assignment = Assignment.create(name: 'assignment 1', enunciation: "assignment 1", type_assignment: Assignment_Type_Individual,
      schedule_attributes: {start_date: Date.today, end_date: Date.today + 10.years})

    allocation_tag = allocation_tags(:al3)
    academic_allocation = assignment.academic_allocations.build(allocation_tag_id: allocation_tag.id)

    assert academic_allocation.valid? rescue false

    assert_equal academic_allocation.errors.full_messages.first, I18n.t(:final_date_smaller_than_offer, scope: [:assignment, :notifications], end_date_offer: I18n.l(allocation_tag.group.offer.end_date.to_date))
  end

end
