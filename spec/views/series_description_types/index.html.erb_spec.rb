require 'spec_helper'

describe "series_description_types/index.html.erb" do
  before(:each) do
    assign(:series_description_types, [
      stub_model(SeriesDescriptionType,
        :id => 1,
        :series_description_type => "Series Description Type"
      ),
      stub_model(SeriesDescriptionType,
        :id => 1,
        :series_description_type => "Series Description Type"
      )
    ])
  end

  it "renders a list of series_description_types" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Series Description Type".to_s, :count => 2
  end
end
