class Allocation < ActiveRecord::Base

  belongs_to :allocation_tag
  belongs_to :user
  belongs_to :profile

  def self.enrollments(args = {})
    where = ["t1.profile_id = #{Profile.find_by_types(Profile_Type_Student).id}", 't2.group_id IS NOT NULL']
    unless args.empty? or args.nil?
      where << "t3.offer_id = #{args['offer_id']}" if args.include?('offer_id')
      where << "t3.id = #{args['group_id']}" if args.include?('group_id')
    end

    query = <<SQL
      SELECT t1.*,
             t3.code          AS group,
             t4.name          AS user_name
        FROM allocations      AS t1
        JOIN allocation_tags  AS t2 ON t2.id = t1.allocation_tag_id
        JOIN groups           AS t3 ON t3.id = t2.group_id
        JOIN users            AS t4 ON t4.id = t1.user_id
       WHERE #{where.join(' AND ')}
       ORDER BY t4.name, t1.status
SQL

    self.find_by_sql(query)
  end
  
end
