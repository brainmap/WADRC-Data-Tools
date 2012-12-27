require 'spec_helper'

describe "CgQueryTns" do
  describe "GET /cg_query_tns" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get cg_query_tns_path
      response.status.should be(200)
    end
  end
end
