require 'spec_helper'

describe "lookup_drugclasses/new.html.erb" do
  before(:each) do
    assign(:lookup_drugclass, stub_model(LookupDrugclass,
      :epodrugclass => "MyString",
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_drugclass form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_drugclasses_path, :method => "post" do
      assert_select "input#lookup_drugclass_epodrugclass", :name => "lookup_drugclass[epodrugclass]"
      assert_select "input#lookup_drugclass_description", :name => "lookup_drugclass[description]"
    end
  end
end
