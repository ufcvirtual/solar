require 'test_helper'

class  ScheduleTest < ActiveSupport::TestCase

  fixtures :discussions, :schedules, :allocation_tags

  test "novo schedule deve ter data inicial" do
    schedule = Schedule.create(:end_date => schedules(:schedule24).end_date)

    assert (not schedule.valid?)
    assert_equal schedule.errors[:start_date].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test "data inicial deve ser menor que a data final" do
    schedule = Schedule.create(:start_date => schedules(:schedule18).start_date, :end_date => schedules(:schedule25).start_date)    

    assert (not schedule.valid?)
    assert_equal schedule.errors[:start_date].first, I18n.t(:range_date_error, :scope => [:discussion, :errors])
  end

  test "metodo 'can_destroy?'" do
    schedule1 = schedules(:schedule24) # não possui dependências
    schedule2 = schedules(:schedule18) # possui dependências (fóruns)

    assert_difference("Schedule.count", -1) do
      schedule1.destroy
    end

    assert_no_difference("Schedule.count") do
      schedule2.destroy
    end

    assert (not Schedule.exists?(schedule1))
    assert (Schedule.exists?(schedule2))
  end

  test "nao pode ser de datas passadas" do
    schedule = Schedule.create(start_date: Date.today - 1.year, end_date: Date.today, verify_current_date: true)

    assert schedule.invalid?
    assert_equal schedule.errors[:start_date].first, I18n.t(:current_year, scope: [:schedules, :errors])

    schedule = Schedule.create(start_date: Date.today - 1.month, end_date: Date.today - 1.day, verify_current_date: true)

    assert schedule.invalid?
    assert_equal schedule.errors[:end_date].first, I18n.t(:current_date, scope: [:schedules, :errors])
  end

  test "data final obrigatoria quando passado parametro" do
    schedule = Schedule.create(start_date: Date.today - 1.month, end_date: nil, check_end_date: true)

    assert schedule.invalid?
    assert_equal schedule.errors[:end_date].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

end
