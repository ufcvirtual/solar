require 'test_helper'

class UsuarioTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end

  test "senha_certa_123456" do
	@usuario_teste = Usuario.new
	puts @usuario_teste.sha1('123456')
    assert_equal @usuario_teste.sha1('123456'),'7c4a8d09ca3762af61e59520943dc26494f8941b'
  end

end
