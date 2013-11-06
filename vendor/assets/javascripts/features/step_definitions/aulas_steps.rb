Entao /^eu deverei ver o link "([^"]*)"$/ do |link|
  find_link(link).visible?
end

Entao /^eu deverei ver a linha de aulas disponiveis$/ do |tabela|
	tabela.hashes.each do |linha|	   
      xpath = "//table/tbody/tr[   descendant::a[contains(.,'#{linha[:AulasDisponiveis]}')]    and   child::td[contains(., '#{linha[:DataAcesso]}')]   ]"
	    page.should have_xpath(xpath)
	end
end