require 'spec_helper'

describe "LookupGenders" do
  describe "GET /lookup_genders" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get lookup_genders_path
      response.status.should be(200)
    end
  end
end
