require 'spec_helper'

describe "ScanProceduresVgroups" do
  describe "GET /scan_procedures_vgroups" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get scan_procedures_vgroups_path
      response.status.should be(200)
    end
  end
end
