Dado /^que estou em "([^"]*)" referente a "([^"]*)"$/ do |page_name, curso|
  visit path_to(page_name) + curso
end
