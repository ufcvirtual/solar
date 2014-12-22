class Score # < ActiveRecord::Base

  def self.informations(user_id, at_id, related: nil, type_hash: true)
    at = at_id.is_a?(AllocationTag) ? at_id : AllocationTag.find(at_id)

    assignments = Assignment.joins(:academic_allocations, :schedule).includes(sent_assignments: :assignment_comments) \
                    .where(academic_allocations: {allocation_tag_id:  at.id}) \
                    .select("assignments.*, schedules.start_date AS start_date, schedules.end_date AS end_date") \
                    .order("start_date") if at.is_student?(user_id)

    discussions = Discussion.posts_count_by_user(user_id, at_id)

    history_access = LogAccess.where(log_type: LogAccess::TYPE[:group_access], user_id: user_id, allocation_tag_id: related || at.related)

    if type_hash
      {
        assignments: assignments,
        discussions: discussions,
        history_access: history_access
      }
    else
      [assignments, discussions, history_access]
    end
  end

end
