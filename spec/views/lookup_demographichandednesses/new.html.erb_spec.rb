require 'spec_helper'

describe "lookup_demographichandednesses/new.html.erb" do
  before(:each) do
    assign(:lookup_demographichandedness, stub_model(LookupDemographichandedness,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_demographichandedness form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_demographichandednesses_path, :method => "post" do
      assert_select "input#lookup_demographichandedness_description", :name => "lookup_demographichandedness[description]"
    end
  end
end
