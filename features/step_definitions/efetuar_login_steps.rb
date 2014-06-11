#language: pt

Dado /^que tenho "([^"]*)"$/ do |name, table|
  # table is a Cucumber::Ast::Table
	table.hashes.each do |hash|
    #		User.create(hash)
		FactoryGirl.create(name.singularize, hash)
	end

end

Dado /^que estou em "([^"]*)"$/ do |page_name|
  visit path_to(page_name)
end

Dado /^tento acessar "([^"]*)"$/ do |page_name|
  visit path_to(page_name)
end

Dado /^vou para a pagina "([^"]*)"$/ do |page_name|
  visit path_to(page_name)
end


Dado /^preencho o campo "([^"]*)" com "([^"]*)"$/ do |selector, value|
  fill_in selector, :with => value
end

Quando /^eu clicar em "([^"]*)"$/ do |button|
  click_button(button)
end

Quando /^eu clicar no link "([^"]*)"$/ do |link|
  first(:link, link).click
end

Entao /^eu deverei ver "([^"]*)"$/ do |text|
  	if page.respond_to? :should
  		page.should have_content(text)
      #find('body').has_content?(text)
  	else
  		assert page.has_content?(text)
  	end
end

Entao /^eu deverei ver o alerta "([^"]*)"$/ do |text|
  if page.respond_to? :should
    expect(page).to have_content(text)
  end
end

Entao /^eu deverei ver a categoria de titulo "([^"]*)"$/ do |text|
  find('legend', :text => text)
end

Entao /^eu deverei ver a coluna de titulo "([^"]*)"$/ do |text|
  first('th>div', :text => text)
end

Entao /^eu deverei ver o campo "([^"]*)"/ do |selector|
  find_field(selector)
end

# Teste

Quando /^eu clicar no link de conteudo "([^"]*)"$/ do |link|
  click_link(link)
end

Entao /^eu deverei visualizar "([^"]*)"$/ do |texto|
  page.should have_content(texto)
end

Entao 'eu deverei ter option com valor "$texto"' do |texto|
  #assert_equal texto, page.find_field('')
  #page.find_field(texto).value
  find_by_id('status', :visible => false).find('option', :visible => false, :text => texto)
  #find_link(texto, :visible => false)
  #find_by_id('ui-id-6')
  #page.find(".ui-widget-content.ui-combobox-input.ui-autocomplete-input", :value => texto)
end

Entao 'eu deverei ver input com valor "$text" em "$parent"' do |text, parent|
  #find_field(texto)
  find(parent).value.should eq text
end

Entao /^eu nao deverei ver "([^"]*)"$/ do |text|
  if page.respond_to? :should
    page.should have_no_content(text)
  else
    assert page.has_no_content?(text)
  end
end

Dado /^que estou logado no sistema com usuario user$/ do
  #User.create(:login => 'user', :email => 'user@tester.com', :password => '123456', :name => 'User')
  visit path_to("Login")
  fill_in("username", :with => "user")
  fill_in("password", :with => "123456")
  click_button "submit-login"
  if page.respond_to? :should
    page.should have_content("Novidades")
  else
    assert page.has_content?("Novidades")
  end
end


Dado /^que eu nao estou logado no sistema com usuario user$/ do
end

Dado /^que estou logado com o usuario "([^\"]*)" e com a senha "([^\"]*)"$/ do |username, password|
  visit path_to("Login")
  fill_in "login", :with => username
  fill_in "password", :with => password
  click_button "submit-login"
end

Dado /^que eu selecionei "([^"]*)" de "([^"]*)"$/ do |value, field|
  page.select(value, :from => field)
end
