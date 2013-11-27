require 'spec_helper'

describe "series_description_types/edit.html.erb" do
  before(:each) do
    @series_description_type = assign(:series_description_type, stub_model(SeriesDescriptionType,
      :id => 1,
      :series_description_type => "MyString"
    ))
  end

  it "renders the edit series_description_type form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => series_description_type_path(@series_description_type), :method => "post" do
      assert_select "input#series_description_type_id", :name => "series_description_type[id]"
      assert_select "input#series_description_type_series_description_type", :name => "series_description_type[series_description_type]"
    end
  end
end
