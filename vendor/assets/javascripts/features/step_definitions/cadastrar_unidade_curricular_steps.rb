Entao /^eu deverei ver a linha de Unidade Curricular$/ do |tabela|
	tabela.hashes.each do |linha|
		xpath = "//table/tbody/tr[ child::td[contains(., '#{linha[:Codigo]}')] and child::td[contains(., '#{linha[:Nome]}')] and child::td[contains(., '#{linha[:Categoria]}')] ]"
		page.should have_xpath(xpath)
	end
end

Entao /^eu nao deverei ver a linha de Unidade Curricular$/ do |tabela| 
	tabela.hashes.each do |linha|
		xpath = "//table/tbody/tr[ child::td[contains(., '#{linha[:Codigo]}')] and child::td[contains(., '#{linha[:Nome]}')] and child::td[contains(., '#{linha[:Categoria]}')] ]"
		page.should have_no_xpath(xpath)
	end
end

Quando /^eu clicar no botao "(.*?)" da linha que contem o item "(.*?)" da tabela$/ do |element, texto|
  xpath = "//table/tbody/tr[ child::td[contains(.,'#{texto}')] ]"
  within(:xpath, xpath) do
  	page.execute_script("$('#{element}').click(); ")
  end
end

Entao "a pagina deve aceitar a proxima confirmacao" do
  sleep 4
  confirm_dialog
  # page.evaluate_script('window.confirm = function() { return true; }')
end


module ConfirmDialog
  def confirm_dialog(message = nil)
    alert = page.driver.browser.switch_to.alert

    if message.nil? || alert.text == message
      alert.accept
    else
      alert.dismiss
    end
  end
end