require 'spec_helper'

describe "lookup_drugclasses/edit.html.erb" do
  before(:each) do
    @lookup_drugclass = assign(:lookup_drugclass, stub_model(LookupDrugclass,
      :epodrugclass => "MyString",
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_drugclass form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_drugclass_path(@lookup_drugclass), :method => "post" do
      assert_select "input#lookup_drugclass_epodrugclass", :name => "lookup_drugclass[epodrugclass]"
      assert_select "input#lookup_drugclass_description", :name => "lookup_drugclass[description]"
    end
  end
end
