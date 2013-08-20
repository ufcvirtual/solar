Dado 'que eu pressionei a tecla "$tecla" no campo "$campo" de "$parent_div"' do |tecla, campo, parent_div|
  if parent_div.empty?
	 find_field(campo).native.send_key(tecla.to_sym)
  else
    xpath = "//div[@class='#{parent_div}']"
    within(:xpath, xpath) do
      find_field(campo).native.send_key(tecla.to_sym)
    end
  end
end

Dado 'que eu cliquei em "$elemento"' do |elemento|
	find(elemento).click
end

Dado 'que eu preenchi "$element" de "$parent_div" com "$texto"' do |element, parent_div, texto|
  xpath = "//div[@class='#{parent_div}']"
  within(:xpath, xpath) do
    fill_in element, :with => texto
  end
end

Dado 'que eu cliquei no link "$element" de "$parent_div"' do |element, parent_div|
  xpath = "//div[@class='#{parent_div}']"
  within(:xpath, xpath) do
    find(element).click
  end
end

Entao /^eu deverei ver a linha de Cursos$/ do |tabela| 
  tabela.hashes.each do |linha|
    xpath = "//table/tbody/tr[ child::td[contains(., '#{linha[:Codigo]}')] and child::td[contains(., '#{linha[:Nome]}')] ]"
    page.should have_xpath(xpath)
  end
end

Entao /^eu nao deverei ver a linha de Cursos$/ do |tabela| 
  tabela.hashes.each do |linha|
    xpath = "//table/tbody/tr[ child::td[contains(., '#{linha[:Codigo]}')] and child::td[contains(., '#{linha[:Nome]}')] ]"
    page.should have_no_xpath(xpath)
  end
end

Entao /^eu deverei ver a linha de Ofertas$/ do |tabela| 
  tabela.hashes.each do |linha|
    xpath = "//table/tbody/tr[ child::td[contains(., '#{linha[:Tipo]}')] and child::td[contains(., '#{linha[:Curso]}')] and child::td[contains(., '#{linha[:Oferta]}')] ]"
    page.should have_xpath(xpath)
  end
end

Entao /^eu deverei ver a linha de Turmas$/ do |tabela| 
  tabela.hashes.each do |linha|
    xpath = "//table/tbody/tr[ child::td[contains(., '#{linha[:Codigo]}')] ]"
    page.should have_xpath(xpath)
  end
end


