require 'spec_helper'

describe "lookup_demographicrelativerelationships/edit.html.erb" do
  before(:each) do
    @lookup_demographicrelativerelationship = assign(:lookup_demographicrelativerelationship, stub_model(LookupDemographicrelativerelationship,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_demographicrelativerelationship form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_demographicrelativerelationship_path(@lookup_demographicrelativerelationship), :method => "post" do
      assert_select "input#lookup_demographicrelativerelationship_description", :name => "lookup_demographicrelativerelationship[description]"
    end
  end
end
