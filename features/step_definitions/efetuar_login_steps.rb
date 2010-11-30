Dado /^que tenho "([^"]*)"$/ do |arg1, table|
  # table is a Cucumber::Ast::Table
	table.hashes.each do |hash|
		User.create(hash)
	end
end

Dado /^que estou em "([^"]*)"$/ do |page_name|
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

