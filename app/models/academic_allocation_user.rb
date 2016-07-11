class AcademicAllocationUser < ActiveRecord::Base

	belongs_to :discussion_post
	has_many :academic_allocation

  def self.get_or_create_academic_allocation_user(tool, academic_allocation, user_id, group_assignment_id=nil)

    allu = AcademicAllocationUser.joins('LEFT JOIN academic_allocations ON academic_allocations.id=academic_allocation_users.academic_allocation_id')
    	 .where('academic_allocation_users.user_id= ? AND academic_tool_type= ? AND academic_allocation_id= ? ', user_id, tool, academic_allocation.id)
    	 .select("DISTINCT academic_allocation_users.id")

  	if allu.blank? #cria um novo
  		@academic_allocation_user = AcademicAllocationUser.create(academic_allocation_id: academic_allocation.id, user_id: user_id, group_assignment_id: group_assignment_id, grade: 0, status: 0)
  		id = @academic_allocation_user.id
  	else
  		id = allu.last.id
  		alluser = AcademicAllocationUser.find(id)
  		if alluser.grade > 0
  			alluser.new_after_evaluation = true
  			alluser.save
  		end	
  	end
  	id	
  end  

  def update_grade_and_frequency(grade, frequency)
  	max_working_hours = AcademicAllocation.find(self.academic_allocation_id).max_working_hours
  	g = grade>10 ? 10.00 : grade
    f = frequency>max_working_hours ? max_working_hours : frequency
  	self.grade = g
  	self.working_hours = f
  	self.new_after_evaluation = true
    self.save
  end

  def self.get_grade_posts_user(user_id, tool, academic_allocation_id)
  	allu = AcademicAllocationUser.joins('LEFT JOIN academic_allocations ON academic_allocations.id=academic_allocation_users.academic_allocation_id')
    	.where('academic_allocation_users.user_id= ? AND academic_tool_type= ? AND academic_allocation_id= ? ', user_id, tool, academic_allocation_id).last
    
    grade = allu.blank? ? '' : 	allu.grade
  end	

end
