require 'test_helper'

class  OfferTest < ActiveSupport::TestCase

  fixtures :courses, :curriculum_units

  test "deve pertencer a um curso" do
    offer = Offer.create(:course => nil)

    assert offer.invalid?
    assert_equal offer.errors[:course].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test "deve pertencer a uma unidade curricular" do
    offer = Offer.create(:curriculum_unit => nil)

    assert offer.invalid?
    assert_equal offer.errors[:curriculum_unit].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test "deve ter um semestre" do
    offer = Offer.create(:semester => nil)

    assert offer.invalid?
    assert_equal offer.errors[:semester].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  private
    def create(options={})
      Offer.create({
        :semester => "1900.2", 
        :start_date => "2012-12-01", 
        :end_date => "2012-12-31", 
        :course => courses(:c2), 
        :curriculum_unit => curriculum_units(:r5)
        }.merge(options))
    end

end