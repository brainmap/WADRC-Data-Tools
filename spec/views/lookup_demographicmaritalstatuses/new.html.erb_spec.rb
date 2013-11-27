require 'spec_helper'

describe "lookup_demographicmaritalstatuses/new.html.erb" do
  before(:each) do
    assign(:lookup_demographicmaritalstatus, stub_model(LookupDemographicmaritalstatus,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_demographicmaritalstatus form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_demographicmaritalstatuses_path, :method => "post" do
      assert_select "input#lookup_demographicmaritalstatus_description", :name => "lookup_demographicmaritalstatus[description]"
    end
  end
end
