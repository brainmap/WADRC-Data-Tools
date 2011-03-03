# Basic UI Steps

Then /^(?:|I )should see "([^\"]*)" within the (\d+)(?:st|nd|rd|th) row$/ do |regexp, pos|
  # Only select children within table body
  selector = "table tbody tr:nth-child(#{pos.to_i})"
  within(selector) do |content|
    regexp = Regexp.new(regexp)
    if content.respond_to? :should
      content.should contain(regexp)
    else
      assert_match(regexp, content)
    end
  end
end
