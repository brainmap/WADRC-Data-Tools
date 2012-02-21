require 'spec_helper'

describe "LookupDemographicrelativerelationships" do
  describe "GET /lookup_demographicrelativerelationships" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get lookup_demographicrelativerelationships_path
      response.status.should be(200)
    end
  end
end
