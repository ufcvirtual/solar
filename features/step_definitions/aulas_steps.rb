Entao /^eu deverei ver o link "([^"]*)"$/ do |link|
  find_link(link).visible?
end

Entao /^eu deverei ver a linha de aulas disponiveis$/ do |tabela|
	tabela.hashes.each do |linha|
	    #xpath = "//table/tr[   child::td[contains('#{linha[:AulasDisponiveis]}')]   and   child::td[contains(., '#{linha[:DataAcesso]}')]   ]"


      xpath = "//table/tr[  descendant::a[@text='#{linha[:AulasDisponiveis]}']  ]"


      
#/html/body/div[2]/div/div/table/tbody/tr[5]/td
      #xpath = "//table/tr[   child::td[contains(.//a[@href]/text(), '#{linha[:AulasDisponiveis]}' ))]   and   child::td[contains(., '#{linha[:DataAcesso]}')]   ]"
      #xpath = "//table/tr[   descendant::a[@value='#{linha[:AulasDisponiveis]}']   and   child::td[contains(., '#{linha[:DataAcesso]}')]   ]"
      #    descendant::a[@href][@value='#{linha[:AulasDisponiveis]}']   and

	    page.should have_xpath(xpath)


	end
end