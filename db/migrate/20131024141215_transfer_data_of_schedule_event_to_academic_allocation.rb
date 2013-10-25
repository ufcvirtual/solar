class TransferDataOfScheduleEventToAcademicAllocation < ActiveRecord::Migration
  def up
    ScheduleEvent.all.each do |schedule_event|
      AcademicAllocation.create(allocation_tag_id: schedule_event.allocation_tag_id, academic_tool_id: schedule_event.id, academic_tool_type: 'ScheduleEvent')
    end

    change_table :schedule_events do |t|
      t.remove :allocation_tag_id
    end
  end

  def down
    change_table :schedule_events do |t|
      t.references :allocation_tag
      t.foreign_key :allocation_tags
    end

    AcademicAllocation.where(academic_tool_type: 'ScheduleEvent').each do |academic_allocation|
      ScheduleEvent.find(academic_allocation.academic_tool_id).update_attribute(:allocation_tag_id, academic_allocation.allocation_tag_id)
      academic_allocation.destroy
    end
  end
end
