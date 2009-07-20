require 'test_helper'

class VisitTest < Test::Unit::TestCase # < ActiveSupport::TestCase
  # Replace this with your real tests.
  def testVisitFixtures # "visit is in synch with other tables" do
    v = Visit.find_by_rmr("RMR123")
     assert_equal  "aaron", v.user.login
     assert_equal "Flair", v.protocol.name
     assert v.image_datasets.length > 0
  end
end
