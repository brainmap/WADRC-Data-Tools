require 'spec_helper'

describe "QDataForms" do
  describe "GET /q_data_forms" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get q_data_forms_path
      response.status.should be(200)
    end
  end
end
