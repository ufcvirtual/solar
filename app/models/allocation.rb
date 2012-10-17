class Allocation < ActiveRecord::Base

  belongs_to :allocation_tag
  belongs_to :user
  belongs_to :profile

  has_one :course,          :through => :allocation_tag, :conditions => ["course_id is not null"]
  has_one :curriculum_unit, :through => :allocation_tag, :conditions => ["curriculum_unit_id is not null"]
  has_one :offer,           :through => :allocation_tag, :conditions => ["offer_id is not null"]
  has_one :group,           :through => :allocation_tag, :conditions => ["group_id is not null"]

  def groups
    allocation_tag.groups
  end

  def self.enrollments(args = {})
    where = ["t1.profile_id = #{Profile.find_by_types(Profile_Type_Student).id}", 't2.group_id IS NOT NULL']
    unless args.empty? or args.nil?
      where << "t3.offer_id = #{args['offer_id']}" if args.include?('offer_id')
      where << "t3.id IN (#{args['group_id'].join(',')})" if args.include?('group_id')
      where << "t1.status = #{args['status']}" if args.include?('status') and args['status'] != ''
    end

    query = <<SQL
      SELECT t1.*,
             t3.code          AS group_code,
             t4.name          AS user_name
        FROM allocations      AS t1
        JOIN allocation_tags  AS t2 ON t2.id = t1.allocation_tag_id
        JOIN groups           AS t3 ON t3.id = t2.group_id
        JOIN users            AS t4 ON t4.id = t1.user_id
       WHERE #{where.join(' AND ')}
       ORDER BY t4.name, t1.status
SQL

    self.find_by_sql(query)
    
    # Allocation.joins([:allocation_tag => :group], :user).where(profile_id: 1).order("users.name").order("allocations.status")

  end

end
