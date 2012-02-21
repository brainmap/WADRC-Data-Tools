require 'spec_helper'

describe "lookup_imagingplanes/show.html.erb" do
  before(:each) do
    @lookup_imagingplane = assign(:lookup_imagingplane, stub_model(LookupImagingplane,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
