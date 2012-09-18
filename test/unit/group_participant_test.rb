require 'test_helper'

class  GroupParticipantTest < ActiveSupport::TestCase

  fixtures :group_participants, :group_assignments

  test "recupera todas os participantes de um grupo" do 
  	all_group_participants_method = GroupParticipant.all_by_group_assignment(group_assignments(:a1).id)
  	all_group_participants = GroupParticipant.all(:select => "user_id, id", :conditions => ["group_assignment_id = #{group_assignments(:a1).id}", :order => "users.name", :includes => :user])
  	assert_equal(all_group_participants, all_group_participants_method)
  end

end
