require 'test_helper'

class  GroupTest < ActiveSupport::TestCase

  test "deve pertencer a uma oferta" do
    group = Group.create code: "Turma 01"

    assert group.invalid?
    assert_equal I18n.t(:blank, scope: [:activerecord, :errors, :messages]), group.errors[:offer_id].first
  end

  test "deve ter um codigo" do
    group = Group.create offer_id: 3

    assert group.invalid?
    assert_equal I18n.t(:blank, scope: [:activerecord, :errors, :messages]), group.errors[:code].first
  end

  test "deve ter um codigo unico" do
    group1 = Group.create offer_id: 3, code: "Turma 01"
    group2 = Group.create offer_id: 3, code: "Turma 01"

    assert group1.valid?
    assert group2.invalid?
    assert_equal I18n.t(:taken, scope: [:activerecord, :errors, :messages]), group2.errors[:code].first
  end

  test "deve ter um codigo de, no maximo, 40 caracteres" do
    group1 = Group.create offer_id: 3, code: "Turma com codigo menor que 40 caracteres"
    group2 = Group.create offer_id: 3, code: "Turma com codigo maior que quarenta caracteres"

    assert group1.valid?
    assert group2.invalid?
    assert_equal I18n.t(:too_long, scope: [:activerecord, :errors, :messages], count: 40), group2.errors[:code].first
  end

end