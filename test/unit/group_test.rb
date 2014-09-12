require 'test_helper'

class  GroupTest < ActiveSupport::TestCase

  test "deve pertencer a uma oferta" do
    group = Group.create code: "Turma 01"

    assert group.invalid?
    assert_equal group.errors[:offer_id].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test "deve ter um codigo" do
    group = Group.create offer_id: 3

    assert group.invalid?
    assert_equal group.errors[:code].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test "deve ter um codigo unico" do
    group = Group.create offer_id: 3, code: "QM-CAU"

    assert group.invalid?
    assert_equal group.errors[:code].first, I18n.t(:taken, scope: [:activerecord, :errors, :messages])
  end

  test "deve ter um codigo de, no maximo, 40 caracteres" do
    group = Group.create offer_id: 3, code: "Turma com codigo maior que quarenta caracteres"

    assert group.invalid?
    assert_equal group.errors[:code].first, I18n.t(:too_long, scope: [:activerecord, :errors, :messages], count: 40)
  end

end