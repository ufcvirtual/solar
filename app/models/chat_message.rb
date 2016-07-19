class ChatMessage < ActiveRecord::Base

  belongs_to :academic_allocation, conditions: { academic_tool_type: 'ChatRoom' }
  belongs_to :allocation

  has_one :user, through: :allocation
  has_one :chat_room, through: :academic_allocation

  trigger.after(:insert) do
    # AcademicAllocationUser(id: integer, academic_allocation_id: integer, user_id: integer, group_assignment_id: integer, grade: float, working_hours: integer, status: integer, new_after_evaluation: boolean)
    "INSERT INTO academic_allocation_users (academic_allocation_id, user_id) VALUES (NEW.academic_allocation_id, NEW.user_id);
    

select 42, 'New Company Name'
from company
where not exists (select 1 from company where unique_id = 42);


    UPDATE academic_allocation_user SET user_count = user_count + 1 WHERE id = NEW.account_id;"
  end
end
