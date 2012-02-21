require 'spec_helper'

describe "lookup_demographicmaritialstatuses/new.html.erb" do
  before(:each) do
    assign(:lookup_demographicmaritialstatus, stub_model(LookupDemographicmaritialstatus,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_demographicmaritialstatus form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_demographicmaritialstatuses_path, :method => "post" do
      assert_select "input#lookup_demographicmaritialstatus_description", :name => "lookup_demographicmaritialstatus[description]"
    end
  end
end
