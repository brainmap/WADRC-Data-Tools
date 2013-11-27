require 'spec_helper'

describe "lookup_lumbarpunctures/edit.html.erb" do
  before(:each) do
    @lookup_lumbarpuncture = assign(:lookup_lumbarpuncture, stub_model(LookupLumbarpuncture,
      :description => "MyString",
      :units => "MyString",
      :range => "MyString"
    ))
  end

  it "renders the edit lookup_lumbarpuncture form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_lumbarpuncture_path(@lookup_lumbarpuncture), :method => "post" do
      assert_select "input#lookup_lumbarpuncture_description", :name => "lookup_lumbarpuncture[description]"
      assert_select "input#lookup_lumbarpuncture_units", :name => "lookup_lumbarpuncture[units]"
      assert_select "input#lookup_lumbarpuncture_range", :name => "lookup_lumbarpuncture[range]"
    end
  end
end
