require 'spec_helper'

describe "lookup_bvmtpercentiles/new.html.erb" do
  before(:each) do
    assign(:lookup_bvmtpercentile, stub_model(LookupBvmtpercentile,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_bvmtpercentile form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_bvmtpercentiles_path, :method => "post" do
      assert_select "input#lookup_bvmtpercentile_description", :name => "lookup_bvmtpercentile[description]"
    end
  end
end
