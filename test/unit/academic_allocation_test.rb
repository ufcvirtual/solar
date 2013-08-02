require 'test_helper'

class AcademicAllocationTest < ActiveSupport::TestCase

  fixtures :assignments, :users, :groups, :group_assignments, :schedules, :allocation_tags

  test "periodo da atividade deve fazer parte do periodo da oferta" do 
    assignment = Assignment.new(:schedule_id => schedules(:schedule15).id, :enunciation => "assignment 1", :type_assignment => Assignment_Type_Individual)

    allocation_tag = allocation_tags(:al3)
    academic_allocation = AcademicAllocation.new(allocation_tag: allocation_tag, academic_tool: assignment)

    assert (not academic_allocation.valid?)    
    assert_equal academic_allocation.errors[:base].first, I18n.t(:final_date_smaller_than_offer, :scope => [:assignment, :notifications], :end_date_offer => allocation_tag.group.offer.start_date.to_date)
  end

end