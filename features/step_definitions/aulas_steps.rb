Entao /^eu deverei ver o link "([^"]*)"$/ do |link|
  find_link(link).visible?
end
