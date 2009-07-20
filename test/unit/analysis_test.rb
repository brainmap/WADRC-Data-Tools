require 'test_helper'

class AnalysisTest < Test::Unit::TestCase
  def testAnalysisFixtures
     a = Analysis.find_by_series_description("analysis1")
     assert_equal "aaron", a.user.login
  end
end
