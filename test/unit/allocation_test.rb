require 'test_helper'

class AllocationTest < ActiveSupport::TestCase

  fixtures :allocations, :allocation_tags, :users, :profiles

  test "cancela perfil do usuario" do
    allocation = allocations(:f)
    allocation.status = Allocation_Cancelled.to_i

    assert allocation.save 
  end

  test "aloca usuario com perfil professor" do
    allocation_test = {
      profile_id: profiles(:prof_titular).id,
      user_id: users(:user).id,
      allocation_tag_id: allocation_tags(:al14).id,
      status: Allocation_Activated.to_i
    }

    allocation = Allocation.create(allocation_test)
    
    assert allocation.allocation_tag.is_user_class_responsible?(allocation.user_id)    
  end

end
