Entao /^eu deverei ver a linha de opcao de matricula$/ do |tabela|
	tabela.hashes.each do |linha|
	    xpath = "//table/tr[ child::td[contains(., '#{linha[:UnidadeCurricular]}')]  and child::td[contains(., '#{linha[:Categoria]}')]  and child::td[contains(., '#{linha[:Turma]}')]  and   (descendant::input[@value='#{linha[:Matricula]}'] or child::td[contains(., '#{linha[:Matricula]}')])       ]"
	    page.should have_xpath(xpath)
	end
end


Entao /^eu nao deverei ver a linha de opcao de matricula$/ do |tabela| 
	 tabela.hashes.each do |linha|
      xpath = "//table/tr[ child::td[contains(., '#{linha[:UnidadeCurricular]}')]  and child::td[contains(., '#{linha[:Categoria]}')]  and child::td[contains(., '#{linha[:Turma]}')]  and   (descendant::input[@value='#{linha[:Matricula]}'] or child::td[contains(., '#{linha[:Matricula]}')])       ]"
	    page.should have_no_xpath(xpath)
	 end
end


Quando /^eu clicar na opcao "([^"]*)" do item "([^"]*)"$/ do |link, texto|
  xpath = "//table/tr[ child::td[contains(.,'#{texto}')] ]"
  within(:xpath, xpath) do
    find_button("#{link}").click
  end
end

#And /I delete "(.*)"/ do |person|
#  # Use webrat or capybara to find row based on 'person' text... then find 'delete' link in row and click it
#  # example (untested, pseudo code)
#  within(:xpath, "//table/tr[contains(#{person})") do
#    find('.deleteLink').click
#  end
#end