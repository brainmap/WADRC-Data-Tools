require 'spec_helper'

describe "lookup_drugunits/edit.html.erb" do
  before(:each) do
    @lookup_drugunit = assign(:lookup_drugunit, stub_model(LookupDrugunit,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_drugunit form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_drugunit_path(@lookup_drugunit), :method => "post" do
      assert_select "input#lookup_drugunit_description", :name => "lookup_drugunit[description]"
    end
  end
end
