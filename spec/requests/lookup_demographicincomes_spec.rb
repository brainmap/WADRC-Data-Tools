require 'spec_helper'

describe "LookupDemographicincomes" do
  describe "GET /lookup_demographicincomes" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get lookup_demographicincomes_path
      response.status.should be(200)
    end
  end
end
