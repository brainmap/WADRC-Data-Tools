require 'spec_helper'

describe "lookup_demographicmaritialstatuses/edit.html.erb" do
  before(:each) do
    @lookup_demographicmaritialstatus = assign(:lookup_demographicmaritialstatus, stub_model(LookupDemographicmaritialstatus,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_demographicmaritialstatus form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_demographicmaritialstatus_path(@lookup_demographicmaritialstatus), :method => "post" do
      assert_select "input#lookup_demographicmaritialstatus_description", :name => "lookup_demographicmaritialstatus[description]"
    end
  end
end
