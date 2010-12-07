Dado /^que tenho "([^"]*)"$/ do |name, table|
  # table is a Cucumber::Ast::Table
	table.hashes.each do |hash|
#		User.create(hash)
		Factory( name.singularize, hash )
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

Entao /^eu deverei ver "([^"]*)"$/ do |text|
	if page.respond_to? :should
		page.should have_content(text)
	else
		assert page.has_content?(text)
	end
end

Dado /^que estou logado no sistema$/ do
  User.create(:login => 'user', :email => 'user@tester.com', :password => 'user123')
  visit path_to("Login")
  fill_in("login_form_name", :with => "user")
  fill_in("Senha", :with => "user123")
  click_button("Entrar")
  if page.respond_to? :should
    page.should have_content("Novidades")
  else
    assert page.has_content?("Novidades")
  end
end


Dado /^que eu nao estou logado$/ do

end


