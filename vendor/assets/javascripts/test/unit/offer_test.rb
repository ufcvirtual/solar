require 'test_helper'

class  OfferTest < ActiveSupport::TestCase

  test "deve pertencer a, ao menos, um curso ou unidade curricular" do
    offer = Offer.create(:course_id => nil, :curriculum_unit_id => nil, semester_id: semesters(:s2013_1).id)

    assert offer.invalid?
    assert_equal offer.errors[:course].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
    assert_equal offer.errors[:curriculum_unit].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test "deve ter um semestre" do
    offer = Offer.create(:course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r5).id, semester_id: nil)

    assert offer.invalid?
    assert_equal offer.errors[:semester].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test "deve ser unica para uma mesma uc e curso" do
    offer1 = Offer.create(:course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r5).id, semester_id: semesters(:s2013_1).id)
    offer2 = Offer.create(:course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r5).id, semester_id: semesters(:s2013_1).id)

    assert offer2.invalid?
    assert_equal offer2.errors.messages.values.flatten.first, I18n.t(:already_exist, scope: [:offers, :error])
  end

end