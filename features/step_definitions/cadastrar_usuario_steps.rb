Dado /^que eu nao estou cadastrado$/ do
end

Dado /^eu clico no link "([^"]*)"$/ do |link|
  click_link(link)
end

Entao /^eu deverei ver o botao "([^"]*)"$/ do |botao|
  find_button(botao).should_not be_nil
end

