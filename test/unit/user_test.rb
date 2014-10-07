require 'test_helper'

class UserTest < ActiveSupport::TestCase

  fixtures :users

  def setup
    @valid_cpf = ENV['VALID_CPF']
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

  test "senha do usuario com SHA1 sem salt correta" do
    @professor = users(:professor)
    assert_equal @professor.encrypted_password, Digest::SHA1.hexdigest('123456')
  end

  test "usuario integrado nao pode alterar determinados dados" do
    user = users(:user4)
    user.name = "Novo nome"

    assert not(user.valid?) # modulo_academico.yml test: integrated: true
    assert_equal user.errors[:name].first, I18n.t("users.errors.ma.only_by")
  end

  test "usuario nao integrado pode alterar qualquer dado" do
    user      = users(:user3)
    user.name = "Novo nome"

    assert user.valid?
  end

  test "sincronizando usuario existente no MA" do
    user = User.new(@user_test)
    assert_difference("User.count") do
      user.cpf = @valid_cpf
      assert user.synchronize # resultado deve ser true
    end
  end

  test "sincronizando usuario nao existente no MA" do
    assert (users(:aluno1).synchronize).nil? # resultado deve ser nil
  end

  test "nao sincronizar usuario existente no MA, mas existe na blacklist" do
    UserBlacklist.create cpf: @valid_cpf, name: @valid_cpf
    @user_test[:cpf] = @valid_cpf
    user = User.new(@user_test)
    assert (user.synchronize).nil?
  end

end
