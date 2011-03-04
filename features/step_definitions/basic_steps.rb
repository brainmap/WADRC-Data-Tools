# Basic UI Steps

Then /^(?:|I )should see the date "([^\"]*)" within the (\d+)(?:st|nd|rd|th) row$/ do |text, pos|
  # Only select children within table body
  date = Chronic.parse(text).strftime('%Y-%m-%d')
  selector = "table tbody tr:nth-child(#{pos.to_i})"
  within(selector) do |content|
    if response.respond_to? :should
      response.should contain(date)
    else
      assert_contain date
    end
  end
end

Then /^(?:|I )should see "([^\"]*)" within the (\d+)(?:st|nd|rd|th) row$/ do |text, pos|
  # Only select children within table body
  selector = "table tbody tr:nth-child(#{pos.to_i})"
  within(selector) do |content|
    if response.respond_to? :should
      response.should contain(text)
    else
      assert_contain text
    end
  end
end