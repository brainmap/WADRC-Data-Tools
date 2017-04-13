# Given /^the following enrollments:$/ do |enrollments|
#   Enrollment.create!(enrollments.hashes)
# end

When /^I delete the (\d+)(?:st|nd|rd|th) enrollment$/ do |pos|
  visit enrollments_path
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following enrollments:$/ do |expected_enrollments_table|
  expected_enrollments_table.diff!(tableish('table tr', 'td,th'))
end
