Entao /^eu deverei ver a migalha "([^"]*)" > "([^"]*)"$/ do |link1, link2|
  page.should have_content(link1+" > "+link2)
end

