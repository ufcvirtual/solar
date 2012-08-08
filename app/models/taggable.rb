module Taggable

	def allocation_tag_association
		AllocationTag.create({self.class.to_s.underscore.to_sym => self})
	end

	def user_editor_allocation
		user_allocation(user_id, Curriculum_Unit_Initial_Profile)
	end

 	def user_allocation(user_id, profile_id)
    	allocation_tag.user_allocation(user_id, profile_id)
 	end

 	def allocations_check
 		
 	end

end