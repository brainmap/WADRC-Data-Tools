require 'spec_helper'

describe "series_description_types/new.html.erb" do
  before(:each) do
    assign(:series_description_type, stub_model(SeriesDescriptionType,
      :id => 1,
      :series_description_type => "MyString"
    ).as_new_record)
  end

  it "renders new series_description_type form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => series_description_types_path, :method => "post" do
      assert_select "input#series_description_type_id", :name => "series_description_type[id]"
      assert_select "input#series_description_type_series_description_type", :name => "series_description_type[series_description_type]"
    end
  end
end
