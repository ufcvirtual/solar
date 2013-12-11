# Clica em um elemento a partir de seu texto, por exemplo um botão de texto "Salvar"
Dado /^que eu cliquei em elemento de texto "([^\"]+)"$/ do |text|
  matcher = ['*', { :text => text }]
  element = page.find(:css, *matcher)
  while better_match = element.first(:css, *matcher)
    element = better_match
  end
  element.click
end

# Útil para botões que não são botões (são links)
E /^eu deverei ver o botao de link com classe "([^\"]+)"$/ do |icon_class|
  find("a.#{icon_class}")
end

# Útil para botões que não são botões (são links)
E /^eu nao deverei ver o botao de link com classe "([^\"]+)"$/ do |icon_class|
  page.should_not have_css("a.#{icon_class}")
end

Quando /^eu clicar no botao de icone com classe "([^\"]+)"$/ do |icon_class|
  find("i.#{icon_class}").click
end

Entao /^eu devo ver o nome deste mes$/ do 
  steps %{Entao eu deverei ver "#{I18n.t("date.month_names")[Date.current.month-1]}"}
end

Entao /^eu devo ver o nome mes passado$/ do 
  steps %{Entao eu deverei ver "#{I18n.t("date.month_names")[(Date.today - 1.month).month-1]}"}
end

Entao /^eu devo ver o nome mes que vem$/ do 
  steps %{Entao eu deverei ver "#{I18n.t("date.month_names")[(Date.today + 1.month).month-1]}"}
end

Entao /^eu devo ver a visualizacao mensal$/ do
  I18n.t("date.abbr_day_names").each do |week_day|
    steps %{Entao eu deverei ver "#{week_day}"}  
  end
  (Date.today.beginning_of_month.day...Date.today.end_of_month.day).each do |month_day|
    steps %{Entao eu deverei ver "#{month_day}"}  
  end
  steps %{Entao eu deverei ver "#{I18n.t("date.month_names")[Date.today.month-1]} #{Date.today.year}"}
end

Entao /^eu devo ver a visualizacao semanal$/ do
  I18n.t("date.abbr_day_names").each do |week_day|
    steps %{Entao eu deverei ver "#{week_day}"}  
  end
  begin_week, end_week = (Date.today.beginning_of_week - 1.day), (Date.today.end_of_week - 1.day)
  steps %{Entao eu deverei ver "#{begin_week.day} #{I18n.t("date.abbr_month_names")[begin_week.month-1]}, #{begin_week.year}"}
  steps %{Entao eu deverei ver "#{end_week.day} #{I18n.t("date.abbr_month_names")[end_week.month-1]}, #{end_week.year}"}
end

Entao /^eu devo ver a visualizacao diaria$/ do
  today = Date.today
  steps %{
    Entao eu deverei ver "#{today.day} #{I18n.t("date.abbr_month_names")[today.month-1]}, #{today.year}"
    E eu deverei ver "#{today.day}/#{today.month}"
    E eu deverei ver "dia todo"
    E eu deverei ver "6am"
    E eu deverei ver "7am"
    E eu deverei ver "1pm"
    E eu deverei ver "2pm"
  }
end
