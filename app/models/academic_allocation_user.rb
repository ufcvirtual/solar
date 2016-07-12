class AcademicAllocationUser < ActiveRecord::Base

  belongs_to :academic_allocation
  belongs_to :user
  belongs_to :group_assignment
	belongs_to :discussion_post

  has_one :allocation_tag, through: :academic_allocation

  validates :user_id, uniqueness: { scope: [:group_assignment_id, :academic_allocation_id] }  

  before_save :if_group_assignment_remove_user_id

  after_save :recalculate_final_grade, if: '(new_record? && !grade.blank?) || grade_changed?'

  def if_group_assignment_remove_user_id
    self.user_id = nil if group_assignment_id
  end

  def users_count
    has_group ? group_assignment.group_participants.count : 1
  end

  def get_user
    [user_id] || group_assignment.group_participants.pluck(&:user_id)
  end

  def recalculate_final_grade
    get_user.each do |user|
        allocations = Allocation.joins(:profile).where(user_id: user, status: Allocation_Activated).where('cast(profiles.types & ? as boolean)', Profile_Type_Student)
        allocation = allocations.where('final_grade IS NOT NULL').first || allocations.first

        allocation.calculate_final_grade
    end
  end

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
