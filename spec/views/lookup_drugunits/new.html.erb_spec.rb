require 'spec_helper'

describe "lookup_drugunits/new.html.erb" do
  before(:each) do
    assign(:lookup_drugunit, stub_model(LookupDrugunit,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_drugunit form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_drugunits_path, :method => "post" do
      assert_select "input#lookup_drugunit_description", :name => "lookup_drugunit[description]"
    end
  end
end
