require 'spec_helper'

describe "lookup_rads/new.html.erb" do
  before(:each) do
    assign(:lookup_rad, stub_model(LookupRad,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_rad form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_rads_path, :method => "post" do
      assert_select "input#lookup_rad_description", :name => "lookup_rad[description]"
    end
  end
end
