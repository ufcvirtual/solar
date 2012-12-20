Dado 'que eu pressionei a tecla "$tecla" no campo "$campo"' do |tecla, campo|
	find_field(campo).native.send_key(tecla.to_sym)
end

Dado 'que eu cliquei em "$elemento"' do |elemento|
	find(elemento).click
end