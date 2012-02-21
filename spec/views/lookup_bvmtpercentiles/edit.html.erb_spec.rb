require 'spec_helper'

describe "lookup_bvmtpercentiles/edit.html.erb" do
  before(:each) do
    @lookup_bvmtpercentile = assign(:lookup_bvmtpercentile, stub_model(LookupBvmtpercentile,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_bvmtpercentile form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_bvmtpercentile_path(@lookup_bvmtpercentile), :method => "post" do
      assert_select "input#lookup_bvmtpercentile_description", :name => "lookup_bvmtpercentile[description]"
    end
  end
end
