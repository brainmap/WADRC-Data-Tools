require 'spec_helper'

describe "lookup_statuses/edit.html.erb" do
  before(:each) do
    @lookup_status = assign(:lookup_status, stub_model(LookupStatus,
      :description => "MyString",
      :status_type => 1
    ))
  end

  it "renders the edit lookup_status form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_status_path(@lookup_status), :method => "post" do
      assert_select "input#lookup_status_description", :name => "lookup_status[description]"
      assert_select "input#lookup_status_status_type", :name => "lookup_status[status_type]"
    end
  end
end
