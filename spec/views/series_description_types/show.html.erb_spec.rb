require 'spec_helper'

describe "series_description_types/show.html.erb" do
  before(:each) do
    @series_description_type = assign(:series_description_type, stub_model(SeriesDescriptionType,
      :id => 1,
      :series_description_type => "Series Description Type"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Series Description Type/)
  end
end
