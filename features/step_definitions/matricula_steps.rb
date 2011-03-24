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
