Entao /^eu deverei ver a tabela$/ do |tabela|
	tabela.hashes.each do |linha|
		linha.each do |chave,valor|
			page.should have_content("#{valor}") || page.find_link("#{valor}").visible?
		end
	end
end

#Entao /^eu não deverei ver a tabela$/ do |tabela|
#	tabela.hashes.each do |linha|
#		linha.each do |chave,valor|
#			page.should have_no_content("#{valor}")
#		end
#	end
#end