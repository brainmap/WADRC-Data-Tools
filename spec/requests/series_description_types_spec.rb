require 'spec_helper'

describe "SeriesDescriptionTypes" do
  describe "GET /series_description_types" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get series_description_types_path
      response.status.should be(200)
    end
  end
end
