require 'spec_helper'

describe "series_description_maps/show.html.erb" do
  before(:each) do
    @series_description_map = assign(:series_description_map, stub_model(SeriesDescriptionMap,
      :id => 1,
      :series_description_type_id => 1,
      :series_description => "Series Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Series Description/)
  end
end
