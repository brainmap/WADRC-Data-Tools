require 'spec_helper'

describe "series_description_maps/index.html.erb" do
  before(:each) do
    assign(:series_description_maps, [
      stub_model(SeriesDescriptionMap,
        :id => 1,
        :series_description_type_id => 1,
        :series_description => "Series Description"
      ),
      stub_model(SeriesDescriptionMap,
        :id => 1,
        :series_description_type_id => 1,
        :series_description => "Series Description"
      )
    ])
  end

  it "renders a list of series_description_maps" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Series Description".to_s, :count => 2
  end
end
