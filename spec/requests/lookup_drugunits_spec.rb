require 'spec_helper'

describe "LookupDrugunits" do
  describe "GET /lookup_drugunits" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get lookup_drugunits_path
      response.status.should be(200)
    end
  end
end
