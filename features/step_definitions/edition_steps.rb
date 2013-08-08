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

