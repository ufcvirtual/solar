Dado /^que eu nao estou cadastrado$/ do
end

Dado /^que eu espero (\d+) segundos$/ do |n|
  sleep(n.to_i)
end

Dado /^eu clico no link "([^"]*)"$/ do |link|
  click_link(link)
end

Entao /^eu deverei ver o botao "([^"]*)"$/ do |botao|
  #first(:button, botao).should_not be_nil
  find_button(botao).should_not be_nil
end

Entao /^eu deverei ver o botao "([^"]*)" em mensagem com id "([^"]*)"$/ do |botao, message_id|
  find('#'+message_id).find_button(botao).should_not be_nil
end

Dado /^que eu preenchi "([^"]*)" com "([^"]*)"$/ do |selector, value|
  fill_in selector, :with => value
end

Dado /^que eu preencho os seguintes(?: within "([^"]*)")?:$/ do |selector, fields|
  with_scope(selector) do
    fields.rows_hash.each do |name, value|
      When %{I fill in "#{name}" with "#{value}"}
    end
  end
end

Dado /^que eu selecionei a "([^"]*)" com "([^"]*)"$/ do |label, value|
  select_date(value, :from => label) 
end

Dado /^que eu selecionei "([^"]*)" com "([^"]*)"$/ do |field, value|
  select(value, :from => field)
end

Dado /^que eu escolhi "([^"]*)" com "([^"]*)"$/ do |field, value|
  select(value, :from => field)
end

Quando /^eu clicar no link da imagem "([^"]*)"$/ do |img_alt|
  #find(:xpath, "//input[@name = '#{img_alt}']").click()
  find(img_alt).click
end
