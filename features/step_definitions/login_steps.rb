Given /^I am not logged in$/ do
end

Given /^I am logged in as "([^\"]*)" with password "([^\"]*)"$/ do |login, password|
  unless login.blank?
    visit login_url
    fill_in "login", :with => login
    fill_in "password", :with => password
    click_button "Log in"
  end
end