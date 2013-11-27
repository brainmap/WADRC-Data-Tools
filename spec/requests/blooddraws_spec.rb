require 'spec_helper'

describe "Blooddraws" do
  describe "GET /blooddraws" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get blooddraws_path
      response.status.should be(200)
    end
  end
end
