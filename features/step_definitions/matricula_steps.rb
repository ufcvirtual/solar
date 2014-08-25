Entao /^eu deverei ver a linha de opcao de matricula$/ do |tabela|
	tabela.hashes.each do |linha|
	    xpath = "//table/tbody/tr[ child::td[contains(., '#{linha[:UnidadeCurricular]}')]  and child::td[contains(., '#{linha[:Categoria]}')]  and child::td[contains(., '#{linha[:Turma]}')]  and   (descendant::input[@value='#{linha[:Matricula]}'] or child::td[contains(., '#{linha[:Matricula]}')])       ]"
	    page.should have_xpath(xpath)
	end
end

Entao /^eu nao deverei ver a linha de opcao de matricula$/ do |tabela| 
	 tabela.hashes.each do |linha|
      xpath = "//table/tr[ child::td[contains(., '#{linha[:UnidadeCurricular]}')]  and child::td[contains(., '#{linha[:Categoria]}')]  and child::td[contains(., '#{linha[:Turma]}')]  and   (descendant::input[@value='#{linha[:Matricula]}'] or child::td[contains(., '#{linha[:Matricula]}')])       ]"
	    page.should have_no_xpath(xpath)
	 end
end

Entao /^eu deverei visualizar a linha de opcao de matricula$/ do |tabela|
	tabela.hashes.each do |linha|
	    xpath = "//table/tbody/tr[ child::td[contains(., '#{linha[:UnidadeCurricular]}')]  and child::td[contains(., '#{linha[:Categoria]}')]  and child::td[contains(., '#{linha[:Turma]}')]  and   (descendant::input[@value='#{linha[:Matricula]}'] or child::td[contains(., '#{linha[:Matricula]}')])       ]"
	    page.should have_xpath(xpath)
  end
end

Entao /^eu nao deverei visualizar a linha de opcao de matricula$/ do |tabela|
	 tabela.hashes.each do |linha|
      xpath = "//table/tbody/tr[ child::td[contains(., '#{linha[:UnidadeCurricular]}')]  and child::td[contains(., '#{linha[:Categoria]}')]  and child::td[contains(., '#{linha[:Turma]}')]  and   (descendant::input[@value='#{linha[:Matricula]}'] or child::td[contains(., '#{linha[:Matricula]}')])       ]"
	    page.should have_no_xpath(xpath)
	 end
end

Quando /^eu clicar na opcao "([^"]*)" do item de matricula "([^"]*)" do semestre "([^"]*)"$/ do |link, texto, semestre|
  xpath = "//table/tbody/tr[ child::td[contains(.,'#{texto}')] and child::td[contains(.,'#{semestre}')] ]"
  # page.should have_xpath(xpath)
  within(:xpath, xpath) do
    find_link("#{link}").click
  end
  # page.driver.browser.switch_to.alert.accept
  #find("table tbody tr td", :text => texto)
end

E /^eu confirmarei a ação$/ do
  page.driver.browser.switch_to.alert.accept
end