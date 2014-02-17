require 'test_helper'
 
# Aqui estão os testes dos métodos do cotnroller assignments
# que, para acessá-los, se faz necessário estar em uma unidade
# curricular. Logo, há a necessidade de acessar o método
# "add_tab" de outro controller. O que não é permitido em testes
# funcionais.

class DiscussionsWithPostsTest < ActionDispatch::IntegrationTest
  fixtures :all
  # para poder realizar o "login_as" sabendo que o sign_in do devise não funciona no teste de integração
  include Warden::Test::Helpers 
  # para reconhecer o método "fixture_file_upload" no teste de integração
  include ActionDispatch::TestProcess

  def setup
    @quimica_tab = add_tab_path(id: 3, context:2, allocation_tag_id: 3)
    @literatura_brasileira_tab = add_tab_path(id: 8, context:2, allocation_tag_id: 8)
  end

  def login(user)
    login_as user, :scope => :user
  end

  ## API - Mobilis
  test "posts de forum criados a partir de uma data" do
  	login(users(:aluno1))
    get @quimica_tab
    get '/discussions/1/posts/news/20001010102410.json'
	correct_response = '[
		{"before":0,"after":0},
		{"id":6,"profile_id":2,"discussion_id":1,"user_id":2,"user_nick":"User 2","level":2,"content":"In hac habitasse platea dictumst.","updated_at":"2014-01-31T00:00:00-03:00","attachments":[]},
		{"id":3,"profile_id":3,"discussion_id":1,"user_id":1,"user_nick":"Usuario do Sistema","level":1,"content":"Sed tempus porttitor felis. Quisque porttitor viverra nisl, eget luctus leo luctus ac.","updated_at":"2014-01-30T00:00:00-03:00","attachments":[]},
		{"id":2,"profile_id":2,"discussion_id":1,"user_id":2,"user_nick":"User 2","level":2,"content":"Praesent quam ipsum, blandit et vehicula quis, gravida non risus. Morbi nec dolor purus.","updated_at":"2014-01-29T00:00:00-03:00","attachments":[]},
		{"id":1,"profile_id":1,"discussion_id":1,"user_id":1,"user_nick":"Usuario do Sistema","level":1,"content":"Lorem ipsum dolor sit amet, consectetur adipiscing elit.","updated_at":"2014-01-28T00:00:00-03:00","attachments":[]}
	]'

	assert_equal JSON.parse(@response.body), JSON.parse(correct_response)
  end

end