Given /^the following (.+) records?$/ do |factory, table|
  table.hashes.each do |hash|
    # Use Chronic to parse natural-language dates.
    ['date', 'created_at'].each do |date_field|
      hash[date_field] = Chronic.parse(hash[date_field])
    end
    Factory(factory, hash)
  end
end