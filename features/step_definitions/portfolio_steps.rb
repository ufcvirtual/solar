#FIXME: fazer esse teste funcionar e substituir o código em ingles da feature portfolio
E /^eu deverei ver uma tabela com as seguintes linhas$/ do |tabela|
  tabela.hashes.each do |linha|
    xpath = "//table/tbody/tr[ child::td[contains(., '#{linha[:Descrição]}')] and child::td[contains(., '#{linha[:Curso]}')] and child::td[contains(., '#{linha[:Oferta]}')] ]"
    page.should have_xpath(xpath)
  end
end