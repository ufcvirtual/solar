
Dado /^que eu nao estou cadastrado$/ do
end

Dado /^eu clico no link "([^"]*)"$/ do |link|
  click_link(link)
end

Entao /^eu deverei ver o botao "([^"]*)"$/ do |botao|
  find_button(botao).should_not be_nil
end

Dado /^que eu preenchi "([^"]*)" com "([^"]*)"$/ do |selector, value|
  fill_in selector, :with => value
end

Dado /^que eu selecionei a "([^"]*)" com "([^"]*)"$/ do |label, value|
  select_date(value, :from => label) 
end
