require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user_test = {
      username: 'user_test',
      cpf: '84635766136',
      name: 'User Test',
      nick: 'User Test',
      birthdate: '2005-03-02',
      email: 'usertest@solar.ufc.br',
      password: '123456'
    }
  end

  test "novo usuario invalido por ter email invalido" do
    @user_test[:email] = 'email@invalido'
    user = User.new(@user_test)

    assert (not user.valid?)
    assert_equal user.errors[:email].first, I18n.t(:invalid, :scope => [:activerecord, :errors, :messages])
  end

  test "novo usuario invalido por ter email repetido" do
    @user_test[:email] = users(:aluno1).email
    user = User.new(@user_test)

    assert (not user.valid?)
    assert_equal user.errors[:email].first, I18n.t(:taken, :scope => [:activerecord, :errors, :messages])
  end

  test "novo usuario invalido por ter CPF invalido" do
    @user_test[:cpf] = '11111111111'
    user = User.new(@user_test)

    assert (not user.valid?)
    assert_equal user.errors[:cpf].first, I18n.t(:new_user_msg_cpf_error)
  end

  test "novo usuario invalido por ter CPF repetido" do
    @user_test[:cpf] = users(:aluno1).cpf
    user = User.new(@user_test)

    assert (not user.valid?)
    assert_equal user.errors[:cpf].first, I18n.t(:taken, :scope => [:activerecord, :errors, :messages])
  end

  test "novo usuario invalido por ter senha curta" do
    @user_test[:password] = '123'
    user = User.new(@user_test)

    assert (not user.valid?)
    assert_equal user.errors[:password].first, I18n.t(:too_short, :count => Devise.password_length.first, :scope => [:activerecord, :errors, :messages])
  end

  test "novo usuario com dados validos" do
    user = User.new(@user_test)
    assert user.valid?
  end

  # test "login correto" do
  #   pending "ainda nao feito"
  # end

  # test "login negado com senha errada" do
  #   pending "ainda nao feito"
  # end

  test "senha do usuario com md5" do
    @professor = users(:professor)
    assert_equal @professor.encrypted_password, Digest::MD5.hexdigest('123456')
  end

end
