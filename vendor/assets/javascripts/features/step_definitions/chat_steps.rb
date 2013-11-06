Entao /^eu deverei ver os meus chats$/ do |tabela|
	tabela.hashes.each do |linha|
	    xpath = "//table/tbody/tr[    child::td[contains(., '#{linha[:Chat]}')]  and child::td[contains(., '#{linha[:Data]}')]   and child::td[contains(., '#{linha[:Hora]}')]         ]"
	    page.should have_xpath(xpath)
	end
end