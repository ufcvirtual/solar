Capybara.add_selector(:element) do
  xpath { |locator| "//*[normalize-space(text())=#{XPath::Expression::StringLiteral.new(locator)}]" }
end

Quando 'eu clicar no item "$locator"' do |locator|
  find(:xpath, XPath::HTML.content(locator)).click
  page.execute_script("toggle_div('div_group_4')")
end

Quando 'eu clicar no grupo "$grupo_id"' do |grupo_id|
	page.execute_script("clickOnGroup("+grupo_id+")")
end

Quando 'eu selecionar o usuario de id "$id"' do |id|
	check('students__'+id)
end

Entao 'eu deverei ver os alunos do grupo com id "$id" selecionados' do |id|
	find('#students__'+id).should be_checked
end