require 'spec_helper'

describe "lookup_rads/edit.html.erb" do
  before(:each) do
    @lookup_rad = assign(:lookup_rad, stub_model(LookupRad,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_rad form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_rad_path(@lookup_rad), :method => "post" do
      assert_select "input#lookup_rad_description", :name => "lookup_rad[description]"
    end
  end
end
