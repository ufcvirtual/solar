Capybara.add_selector(:element) do
  xpath { |locator| "//*[normalize-space(text())=#{XPath::Expression::StringLiteral.new(locator)}]" }
end

Quando 'eu clicar no item "$locator"' do |locator|
  find(:xpath, XPath::HTML.content(locator)).click
  page.execute_script("toggle_div('div_group_4')")
end

Entao /^deverei ir para "([^"]*)"$/ do |page_name|
  visit path_to(page_name)
end