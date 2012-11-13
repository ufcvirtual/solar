Quando 'eu clicar na imagem de id "$id"' do |id|
	page.find(:xpath, "//img[contains(@id, '"+id+"')]").click 
end