require 'spec_helper'

describe "lookup_demographichandednesses/edit.html.erb" do
  before(:each) do
    @lookup_demographichandedness = assign(:lookup_demographichandedness, stub_model(LookupDemographichandedness,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_demographichandedness form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_demographichandedness_path(@lookup_demographichandedness), :method => "post" do
      assert_select "input#lookup_demographichandedness_description", :name => "lookup_demographichandedness[description]"
    end
  end
end
