require 'test_helper'

class ScheduleEventTest < ActiveSupport::TestCase

  test "todo evento precisa de titulo" do
    event_test    = ScheduleEvent.create(title: nil, type_event: Presential_Test, start_hour: "10:30", end_hour: "11:30", place: "Polo A") 
    event_meeting = ScheduleEvent.create(title: nil, type_event: Presential_Meeting, start_hour: "10:30", end_hour: "11:30", place: "Polo A") 
    event_recess  = ScheduleEvent.create(title: nil, type_event: Recess) 
    event_holiday = ScheduleEvent.create(title: nil, type_event: Holiday) 
    event_other   = ScheduleEvent.create(title: nil, type_event: Other)

    assert (event_test.invalid? and event_meeting.invalid? and event_holiday.invalid? and event_recess.invalid?)

    assert_equal event_test.errors[:title].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
    assert_equal event_meeting.errors[:title].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
    assert_equal event_recess.errors[:title].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
    assert_equal event_holiday.errors[:title].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test "prova e encontro precisam de local" do
    event_test    = ScheduleEvent.create(title: "Prova", type_event: Presential_Test, start_hour: "10:30", end_hour: "11:30", place: nil)
    event_meeting = ScheduleEvent.create(title: "Encontro", type_event: Presential_Meeting, start_hour: "10:30", end_hour: "11:30", place: nil)
    event_recess  = ScheduleEvent.create(title: "Recesso", type_event: Recess)
    event_holiday = ScheduleEvent.create(title: "Feriado", type_event: Holiday)

    assert (event_test.invalid? and event_meeting.invalid?)
    assert (event_holiday.valid? and event_recess.valid?)

    assert_equal event_test.errors[:place].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
    assert_equal event_meeting.errors[:place].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test "prova e encontro precisam de hora inicial e final" do
    event_test    = ScheduleEvent.create(title: "Prova", type_event: Presential_Test, start_hour: nil, end_hour: "11:30", place: "Polo A")
    event_meeting = ScheduleEvent.create(title: "Encontro", type_event: Presential_Meeting, start_hour: nil, end_hour: "11:30", place: "Polo A")
    event_recess  = ScheduleEvent.create(title: "Recesso", type_event: Recess)
    event_holiday = ScheduleEvent.create(title: "Feriado", type_event: Holiday)

    assert (event_test.invalid? and event_meeting.invalid?)
    assert (event_holiday.valid? and event_recess.valid?)

    assert_equal event_test.errors[:start_hour].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
    assert_equal event_meeting.errors[:start_hour].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])

    event_test    = ScheduleEvent.create(title: "Prova", type_event: Presential_Test, start_hour: "10:30", end_hour: nil, place: "Polo A")
    event_meeting = ScheduleEvent.create(title: "Encontro", type_event: Presential_Meeting, start_hour: "10:30", end_hour: nil, place: "Polo A")
    
    assert (event_test.invalid? and event_meeting.invalid?)
    assert_equal event_test.errors[:end_hour].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
    assert_equal event_meeting.errors[:end_hour].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test "prova e encontro devem ter hora de inicio e fim no formato definido" do
    event_test    = ScheduleEvent.create(title: "Prova", type_event: Presential_Test, start_hour: "horario", end_hour: "10:00", place: "Polo A")
    event_meeting = ScheduleEvent.create(title: "Encontro", type_event: Presential_Meeting, start_hour: "horario", end_hour: "10:00", place: "Polo A")

    assert (event_test.invalid? and event_meeting.invalid?)

    assert_equal event_test.errors[:start_hour].first, I18n.t(:invalid, scope: [:activerecord, :errors, :messages])
    assert_equal event_meeting.errors[:start_hour].first, I18n.t(:invalid, scope: [:activerecord, :errors, :messages])

    event_test    = ScheduleEvent.create(title: "Prova", type_event: Presential_Test, start_hour: "09:6", end_hour: "10:00", place: "Polo A")
    event_meeting = ScheduleEvent.create(title: "Encontro", type_event: Presential_Meeting, start_hour: "09:6", end_hour: "10:00", place: "Polo A")

    assert (event_test.invalid? and event_meeting.invalid?)

    assert_equal event_test.errors[:start_hour].first, I18n.t(:invalid, scope: [:activerecord, :errors, :messages])
    assert_equal event_meeting.errors[:start_hour].first, I18n.t(:invalid, scope: [:activerecord, :errors, :messages])
  end

  test "prova e encontro devem ter hora final posterior a inicial" do 
    event_test    = ScheduleEvent.create(title: "Prova", type_event: Presential_Test, start_hour: "10:30", end_hour: "10:00", place: "Polo A")
    event_meeting = ScheduleEvent.create(title: "Encontro", type_event: Presential_Meeting, start_hour: "10:30", end_hour: "10:00", place: "Polo A")

    assert (event_test.invalid? and event_meeting.invalid?)

    assert_equal event_test.errors[:end_hour].first, I18n.t(:range_hour_error, scope: [:schedule_events, :error])
    assert_equal event_meeting.errors[:end_hour].first, I18n.t(:range_hour_error, scope: [:schedule_events, :error])
  end

end
