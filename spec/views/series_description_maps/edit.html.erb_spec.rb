require 'spec_helper'

describe "series_description_maps/edit.html.erb" do
  before(:each) do
    @series_description_map = assign(:series_description_map, stub_model(SeriesDescriptionMap,
      :id => 1,
      :series_description_type_id => 1,
      :series_description => "MyString"
    ))
  end

  it "renders the edit series_description_map form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => series_description_map_path(@series_description_map), :method => "post" do
      assert_select "input#series_description_map_id", :name => "series_description_map[id]"
      assert_select "input#series_description_map_series_description_type_id", :name => "series_description_map[series_description_type_id]"
      assert_select "input#series_description_map_series_description", :name => "series_description_map[series_description]"
    end
  end
end
