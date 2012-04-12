require 'spec_helper'

describe "QData" do
  describe "GET /q_data" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get q_data_path
      response.status.should be(200)
    end
  end
end
