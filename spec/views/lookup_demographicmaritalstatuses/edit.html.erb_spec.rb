require 'spec_helper'

describe "lookup_demographicmaritalstatuses/edit.html.erb" do
  before(:each) do
    @lookup_demographicmaritalstatus = assign(:lookup_demographicmaritalstatus, stub_model(LookupDemographicmaritalstatus,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_demographicmaritalstatus form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_demographicmaritalstatus_path(@lookup_demographicmaritalstatus), :method => "post" do
      assert_select "input#lookup_demographicmaritalstatus_description", :name => "lookup_demographicmaritalstatus[description]"
    end
  end
end
