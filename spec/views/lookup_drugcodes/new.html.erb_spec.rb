require 'spec_helper'

describe "lookup_drugcodes/new.html.erb" do
  before(:each) do
    assign(:lookup_drugcode, stub_model(LookupDrugcode,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_drugcode form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_drugcodes_path, :method => "post" do
      assert_select "input#lookup_drugcode_description", :name => "lookup_drugcode[description]"
    end
  end
end
