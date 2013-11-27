require 'spec_helper'

describe "QuestionformScanProtocols" do
  describe "GET /questionform_scan_protocols" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get questionform_scan_protocols_path
      response.status.should be(200)
    end
  end
end
