require 'test_helper'

class  SemesterTest < ActiveSupport::TestCase

  test "deve ter um nome" do
    semester = Semester.create(offer_schedule: schedules(:sc_for_offers4), enrollment_schedule: schedules(:schedule34))

    assert semester.invalid?
    assert_equal semester.errors[:name].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test "deve ter um nome unico" do
    semester = Semester.create(name: "2013.1", offer_schedule: schedules(:sc_for_offers4), enrollment_schedule: schedules(:schedule34))

    assert semester.invalid?
    assert_equal semester.errors[:name].first, I18n.t(:taken, :scope => [:activerecord, :errors, :messages])
  end

  test "deve ter periodo de oferta" do
    semester = Semester.create(name: "2018.1", enrollment_schedule: schedules(:schedule34))

    assert semester.invalid?
    assert_equal semester.errors[:offer_schedule].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test "deve ter periodo de matricula" do
    semester = Semester.create(name: "2018.1", offer_schedule: schedules(:sc_for_offers4))

    assert semester.invalid?
    assert_equal semester.errors[:enrollment_schedule].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

end