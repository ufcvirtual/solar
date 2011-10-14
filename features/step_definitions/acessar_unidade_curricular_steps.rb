Entao /^eu deverei ver a migalha de pao "([^"]*)" > "([^"]*)"$/ do |link1, link2|
  find_link(link1).visible?
  find_link(link2).visible?
  page.should have_content(link1 + " > " + link2)
end

