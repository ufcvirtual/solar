module AdministrationsHelper

	def last_accessed(id)
		last_accessed = Log.find_by_user_id(id)
		if !last_accessed.nil?
			l(last_accessed.created_at.to_date, :format => :default).to_s 
    else
    	" - "
    end
	end

	def allocation_details(allocation_tag)
		AllocationTag.allocation_tag_details(allocation_tag)
	end

end