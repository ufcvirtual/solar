require 'test_helper'

class UserBlacklistTest < ActiveSupport::TestCase

  fixtures :users, :user_blacklist

  test "adicionar CPF a blacklist" do 
    user_bl = UserBlacklist.new cpf: '20943068363', name: 'Owen B. Wilken'
    assert user_bl.save

    user = users(:coorddisc)
    assert_difference('UserBlacklist.count', 1) do
      user.add_to_blacklist
    end
  end

  test "nao adicionar o mesmo CPF mais de uma vez" do
    user_bl = UserBlacklist.new cpf: '20943068363', name: 'Owen B. Wilken'
    assert user_bl.save

    user_bl2 = user_bl.dup

    assert not(user_bl2.valid?)
    assert user_bl2.errors[:cpf].any?
    assert not(user_bl2.save)
  end

  test "nao adicionar CPF invalido" do
    user_bl = UserBlacklist.new cpf: '00000000000', name: 'Owen B. Wilken'
    assert not(user_bl.save)
  end

  test "nao sincronizar usuario com CPF na blacklist" do
    user = users(:coorddisc)
    assert_difference('UserBlacklist.count', 1) do
      user.add_to_blacklist
    end

    assert_nil user.synchronize
  end

  test "remover CPF da blacklist" do
    user_bl = user_blacklist(:user_bl1)
    assert_difference('UserBlacklist.count', -1) do
      user_bl.destroy
    end
  end

  test "nao adicionar aluno de graduacao a distancia a blacklist" do
    user = users(:aluno1)

    assert_no_difference('UserBlacklist.count') do
      user.add_to_blacklist
    end
  end

  test "sincronizar usuario ao retirar seu CPF da blacklist" do
    cpf = "VALID CPF HERE"
    user = users(:coorddisc)
    user.cpf = cpf

    assert user.save

    assert user.synchronize

    user_bl = user.add_to_blacklist

    assert_nil user.synchronize

    user_bl.destroy

    assert user.synchronize
  end

end
