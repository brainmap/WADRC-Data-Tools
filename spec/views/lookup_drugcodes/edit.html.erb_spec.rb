require 'spec_helper'

describe "lookup_drugcodes/edit.html.erb" do
  before(:each) do
    @lookup_drugcode = assign(:lookup_drugcode, stub_model(LookupDrugcode,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_drugcode form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_drugcode_path(@lookup_drugcode), :method => "post" do
      assert_select "input#lookup_drugcode_description", :name => "lookup_drugcode[description]"
    end
  end
end
