require 'spec_helper'

describe "QuestionScanProcedures" do
  describe "GET /question_scan_procedures" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get question_scan_procedures_path
      response.status.should be(200)
    end
  end
end
