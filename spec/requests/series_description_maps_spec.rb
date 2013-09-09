require 'spec_helper'

describe "SeriesDescriptionMaps" do
  describe "GET /series_description_maps" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get series_description_maps_path
      response.status.should be(200)
    end
  end
end
