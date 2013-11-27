require 'spec_helper'

describe "CgQueryTnCns" do
  describe "GET /cg_query_tn_cns" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get cg_query_tn_cns_path
      response.status.should be(200)
    end
  end
end
