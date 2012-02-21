require 'spec_helper'

describe "LookupSources" do
  describe "GET /lookup_sources" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get lookup_sources_path
      response.status.should be(200)
    end
  end
end
