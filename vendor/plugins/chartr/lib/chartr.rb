module Chartr
  include ActiveSupport
  require "chart"
  Dir["#{File.dirname(__FILE__)}/charts/**"].map do |chart|
    require chart if chart =~ /.*?_chart.rb$/
  end
end
