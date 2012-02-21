require 'spec_helper'

describe "lookup_demographicrelativerelationships/new.html.erb" do
  before(:each) do
    assign(:lookup_demographicrelativerelationship, stub_model(LookupDemographicrelativerelationship,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_demographicrelativerelationship form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_demographicrelativerelationships_path, :method => "post" do
      assert_select "input#lookup_demographicrelativerelationship_description", :name => "lookup_demographicrelativerelationship[description]"
    end
  end
end
