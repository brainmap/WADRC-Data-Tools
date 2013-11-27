require 'spec_helper'

describe "LookupImagingplanes" do
  describe "GET /lookup_imagingplanes" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get lookup_imagingplanes_path
      response.status.should be(200)
    end
  end
end
