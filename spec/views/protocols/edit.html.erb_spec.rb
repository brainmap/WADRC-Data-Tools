require 'spec_helper'

describe "protocols/edit.html.erb" do
  before(:each) do
    @protocol = assign(:protocol, stub_model(Protocol,
      :name => "MyString",
      :abbr => "MyString",
      :path => "MyString",
      :description => "MyString"
    ))
  end

  it "renders the edit protocol form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => protocol_path(@protocol), :method => "post" do
      assert_select "input#protocol_name", :name => "protocol[name]"
      assert_select "input#protocol_abbr", :name => "protocol[abbr]"
      assert_select "input#protocol_path", :name => "protocol[path]"
      assert_select "input#protocol_description", :name => "protocol[description]"
    end
  end
end
